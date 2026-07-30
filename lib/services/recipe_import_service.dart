import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/units.dart';
import '../models/models.dart';

/// Thrown when a URL can't be reached or contains no parseable recipe data.
class RecipeImportException implements Exception {
  final String message;
  RecipeImportException(this.message);
  @override
  String toString() => message;
}

/// Result of a successful import: an unsaved [Recipe] + its [RecipeIngredient]s,
/// ready for the caller to review and persist via `RecipeRepository`.
class ParsedRecipe {
  final Recipe recipe;
  final List<RecipeIngredient> ingredients;
  ParsedRecipe(this.recipe, this.ingredients);
}

/// Imports a recipe from a URL by parsing `schema.org/Recipe` JSON-LD
/// microdata embedded in the page's `<script type="application/ld+json">`
/// tags (the format used by nearly all recipe blogs and publishers for SEO).
class RecipeImportService {
  static final _scriptTagPattern = RegExp(
    r'<script[^>]*type=["\x27]application/ld\+json["\x27][^>]*>(.*?)</script>',
    dotAll: true,
    caseSensitive: false,
  );

  static Future<ParsedRecipe> importFromUrl(String url) async {
    final uri = _parseUrl(url);

    late final http.Response response;
    try {
      response = await http
          .get(uri, headers: {'User-Agent': 'Mozilla/5.0 (compatible; SisuMate/1.0)'})
          .timeout(const Duration(seconds: 15));
    } catch (_) {
      throw RecipeImportException('Could not reach that URL');
    }
    if (response.statusCode != 200) {
      throw RecipeImportException('That page returned an error (${response.statusCode})');
    }

    return parseHtml(response.body);
  }

  /// Parses `schema.org/Recipe` JSON-LD out of a page's raw HTML. Pure
  /// function (no network) — the reusable, testable core of [importFromUrl].
  static ParsedRecipe parseHtml(String html) {
    final recipeJson = _extractRecipeJson(html);
    if (recipeJson == null) {
      throw RecipeImportException('No recipe data found on that page');
    }

    final name = (recipeJson['name'] as String?)?.trim();
    if (name == null || name.isEmpty) {
      throw RecipeImportException('That page is missing a recipe name');
    }

    final instructions = _flattenInstructions(recipeJson['recipeInstructions']);
    final cuisine = stringListFromJson(recipeJson['recipeCuisine']);
    final description = (recipeJson['description'] as String?)?.trim();

    final tempId = 'imported_${DateTime.now().millisecondsSinceEpoch}';
    final recipe = Recipe()
      ..supabaseId = tempId
      ..boatSupabaseId = '00000000-0000-0000-0000-000000000000'
      ..name = name
      ..description = (description == null || description.isEmpty) ? null : description
      ..instructions = instructions.isEmpty ? null : instructions
      ..cuisine = cuisine
      ..prepMinutes = _parseIsoDurationMinutes(recipeJson['prepTime'] as String?)
      ..cookMinutes = _parseIsoDurationMinutes(recipeJson['cookTime'] as String?)
      ..recipeType = 'menu'
      ..isBundled = false;

    final rawIngredients = recipeJson['recipeIngredient'];
    final ingredients = <RecipeIngredient>[];
    if (rawIngredients is List) {
      for (var i = 0; i < rawIngredients.length; i++) {
        final line = rawIngredients[i]?.toString().trim();
        if (line == null || line.isEmpty) continue;
        ingredients.add(parseIngredientLine(line, tempId, i));
      }
    }

    return ParsedRecipe(recipe, ingredients);
  }

  static Uri _parseUrl(String input) {
    final trimmed = input.trim();
    Uri? uri = Uri.tryParse(trimmed);
    if (uri == null || !uri.hasScheme) {
      uri = Uri.tryParse('https://$trimmed');
    }
    if (uri == null || uri.host.isEmpty) {
      throw RecipeImportException("That doesn't look like a valid URL");
    }
    return uri;
  }

  static Map<String, dynamic>? _extractRecipeJson(String html) {
    for (final match in _scriptTagPattern.allMatches(html)) {
      final raw = match.group(1);
      if (raw == null) continue;
      dynamic decoded;
      try {
        decoded = jsonDecode(raw.trim());
      } catch (_) {
        continue;
      }
      final found = _findRecipeNode(decoded);
      if (found != null) return found;
    }
    return null;
  }

  static Map<String, dynamic>? _findRecipeNode(dynamic node) {
    if (node is Map<String, dynamic>) {
      final type = node['@type'];
      final isRecipe = type == 'Recipe' || (type is List && type.contains('Recipe'));
      if (isRecipe) return node;
      if (node['@graph'] != null) {
        final found = _findRecipeNode(node['@graph']);
        if (found != null) return found;
      }
      return null;
    }
    if (node is List) {
      for (final item in node) {
        final found = _findRecipeNode(item);
        if (found != null) return found;
      }
    }
    return null;
  }

  static String _flattenInstructions(dynamic instructions) {
    if (instructions == null) return '';
    if (instructions is String) return instructions.trim();

    if (instructions is List) {
      final steps = <String>[];
      for (final item in instructions) {
        if (item is String) {
          steps.add(item);
        } else if (item is Map) {
          if (item['@type'] == 'HowToSection' && item['itemListElement'] is List) {
            for (final sub in item['itemListElement'] as List) {
              if (sub is Map && sub['text'] != null) {
                steps.add(sub['text'].toString());
              } else if (sub is String) {
                steps.add(sub);
              }
            }
          } else if (item['text'] != null) {
            steps.add(item['text'].toString());
          } else if (item['name'] != null) {
            steps.add(item['name'].toString());
          }
        }
      }
      return steps
          .asMap()
          .entries
          .map((e) => '${e.key + 1}. ${e.value.trim()}')
          .join('\n');
    }
    return instructions.toString();
  }

  static int? _parseIsoDurationMinutes(String? iso) {
    if (iso == null) return null;
    final match = RegExp(r'^PT(?:(\d+)H)?(?:(\d+)M)?$').firstMatch(iso.trim());
    if (match == null) return null;
    final hours = int.tryParse(match.group(1) ?? '0') ?? 0;
    final minutes = int.tryParse(match.group(2) ?? '0') ?? 0;
    final total = hours * 60 + minutes;
    return total == 0 ? null : total;
  }

  static final _leadingQuantityPattern = RegExp(
    r'^(\d+\s+\d+/\d+|\d+/\d+|\d+(?:\.\d+)?)\s+([a-zA-Z]+\.?)?\s*(.*)$',
  );

  /// Parses one free-text ingredient line (e.g. "1 1/2 cups flour") into a
  /// [RecipeIngredient]. Public so it can be reused by other importers.
  static RecipeIngredient parseIngredientLine(String line, String recipeId, int sortOrder) {
    double? quantity;
    String? unit;
    String name = line;

    final match = _leadingQuantityPattern.firstMatch(line);
    if (match != null) {
      quantity = _parseQuantityToken(match.group(1)!);
      final possibleUnit = match.group(2)?.toLowerCase().replaceAll('.', '');
      final rest = match.group(3) ?? '';
      if (possibleUnit != null && _knownUnits.contains(possibleUnit)) {
        unit = possibleUnit;
        name = rest.trim();
      } else if (possibleUnit != null && possibleUnit.isNotEmpty) {
        // Not a recognized unit word — treat it as the start of the name.
        name = '$possibleUnit $rest'.trim();
      } else {
        name = rest.trim();
      }
    }

    final lowerName = name.toLowerCase();
    final isOptional = lowerName.contains('optional');
    final isGarnish = lowerName.contains('garnish');

    final (metricQty, metricUnit) =
        UnitConverter.normalizePair(quantity, unit);

    return RecipeIngredient()
      ..supabaseId = '${recipeId}_ing_$sortOrder'
      ..recipeSupabaseId = recipeId
      ..name = name.isEmpty ? line : name
      ..quantity = metricQty
      ..unit = metricUnit
      ..isOptional = isOptional
      ..isGarnish = isGarnish
      ..sortOrder = sortOrder;
  }

  static double? _parseQuantityToken(String token) {
    if (token.contains(' ') && token.contains('/')) {
      final parts = token.split(' ');
      final whole = double.tryParse(parts[0]) ?? 0;
      return whole + (_parseFraction(parts[1]) ?? 0);
    }
    if (token.contains('/')) return _parseFraction(token);
    return double.tryParse(token);
  }

  static double? _parseFraction(String token) {
    final parts = token.split('/');
    if (parts.length != 2) return null;
    final num_ = double.tryParse(parts[0]);
    final den = double.tryParse(parts[1]);
    if (num_ == null || den == null || den == 0) return null;
    return num_ / den;
  }

  static const _knownUnits = {
    'oz', 'ounce', 'ounces', 'lb', 'lbs', 'pound', 'pounds',
    'g', 'gram', 'grams', 'kg', 'kilogram', 'kilograms',
    'ml', 'milliliter', 'milliliters', 'millilitre', 'millilitres',
    'l', 'liter', 'liters', 'litre', 'litres',
    'cup', 'cups', 'tbsp', 'tablespoon', 'tablespoons',
    'tsp', 'teaspoon', 'teaspoons',
    'pint', 'pints', 'quart', 'quarts', 'gallon', 'gallons',
    'clove', 'cloves', 'bunch', 'bunches', 'can', 'cans', 'pinch', 'pinches',
    'slice', 'slices', 'piece', 'pieces', 'stick', 'sticks', 'dash',
    'dashes', 'sprig', 'sprigs', 'fillet', 'fillets', 'head', 'heads',
    'bulb', 'bulbs', 'stalk', 'stalks',
  };
}
