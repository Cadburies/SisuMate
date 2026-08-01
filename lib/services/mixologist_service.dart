import '../models/models.dart';

// -- Data types ----------------------------------------------------------------

class SuggestedIngredient {
  final String name;
  final double quantity;
  final String unit;
  final bool optional;
  const SuggestedIngredient(this.name, this.quantity, this.unit, {this.optional = false});
}

/// MIX3: target drink strength for invent-a-drink.
enum CocktailStrength {
  light,
  session,
  strong;

  String get label => switch (this) {
        CocktailStrength.light => 'Light',
        CocktailStrength.session => 'Session',
        CocktailStrength.strong => 'Strong',
      };

  /// Spirit pour in oz for a single serving (before crew scaling).
  double get spiritOz => switch (this) {
        CocktailStrength.light => 1.25,
        CocktailStrength.session => 2.0,
        CocktailStrength.strong => 2.75,
      };

  /// Acid / sweet pour in oz for a single serving.
  double get balanceOz => switch (this) {
        CocktailStrength.light => 1.0,
        CocktailStrength.session => 0.75,
        CocktailStrength.strong => 0.5,
      };
}

class CocktailSuggestion {
  final String name;
  final List<SuggestedIngredient> ingredients;
  final String instructions;
  final String rationale;
  final String technique; // shake | stir | build | blend
  /// MIX3: serving vessel (e.g. Rocks glass, Coupe).
  final String glassware;
  /// MIX3: light | session | strong label.
  final String strengthLabel;
  /// MIX3: number of servings the quantities are scaled for.
  final int servings;
  /// MIX3: estimated ABV % of the finished drink (approx., after dilution).
  final double? estimatedAbvPercent;

  const CocktailSuggestion({
    required this.name,
    required this.ingredients,
    required this.instructions,
    required this.rationale,
    required this.technique,
    this.glassware = 'Rocks glass',
    this.strengthLabel = 'Session',
    this.servings = 1,
    this.estimatedAbvPercent,
  });
}

class DishSuggestion {
  final String name;
  final List<SuggestedIngredient> ingredients;
  final String instructions;
  final String rationale;
  final String cuisine;
  /// MIX5: pantry items this dish is prioritising (expiring / low stock).
  final List<String> leftoverNotes;

  const DishSuggestion({
    required this.name,
    required this.ingredients,
    required this.instructions,
    required this.rationale,
    required this.cuisine,
    this.leftoverNotes = const [],
  });
}

// -- MIX5: pantry leftover / use-soon ranking ----------------------------------

/// One in-pantry item with a leftover-priority score and human reasons.
class PantryPriorityItem {
  final PantryIngredient ingredient;
  /// Higher = use sooner in tonight's dish.
  final int score;
  final List<String> reasons;

  const PantryPriorityItem({
    required this.ingredient,
    required this.score,
    required this.reasons,
  });
}

// -- MIX1: makeable-tonight ranking --------------------------------------------

/// MIX2: one accepted substitute for a missing recipe line.
class IngredientSubstitute {
  /// Name as written on the recipe.
  final String needed;
  /// Stocked name used instead.
  final String using;
  /// 0.0–1.0 (higher = closer flavor / more standard swap).
  final double confidence;
  /// Short ASCII note for UI (why / caveats).
  final String note;

  const IngredientSubstitute({
    required this.needed,
    required this.using,
    required this.confidence,
    required this.note,
  });

  /// Confidence high enough to count as "covered" for makeable ranking.
  bool get countsAsHave => confidence >= 0.6;

  String get summary =>
      'Use $using for $needed (${(confidence * 100).round()}%: $note)';
}

/// One recipe scored by how many non-optional, non-garnish ingredients you have.
class MakeableRecipeScore {
  final Recipe recipe;
  final int haveCount;
  final int missingCount;
  final List<String> haveNames;
  final List<String> missingNames;
  /// MIX2: substitutes that covered a would-be missing line.
  final List<IngredientSubstitute> substitutesUsed;

  const MakeableRecipeScore({
    required this.recipe,
    required this.haveCount,
    required this.missingCount,
    required this.haveNames,
    required this.missingNames,
    this.substitutesUsed = const [],
  });

  /// 1.0 = fully makeable, 0.0 = missing everything.
  double get completeness {
    final total = haveCount + missingCount;
    if (total == 0) return 1.0;
    return haveCount / total;
  }

  bool get isMakeable => missingCount == 0;

  /// Ready with at least one accepted substitute.
  bool get isMakeableWithSubs =>
      isMakeable && substitutesUsed.isNotEmpty;
}

// -- MIX4: bar low-stock signals -----------------------------------------------

class BarLowStockItem {
  final BarIngredient ingredient;
  /// Human reason (ASCII), e.g. "Last purchase 120 days ago".
  final String reason;
  /// Higher = more urgent (shown first).
  final int urgency;

  const BarLowStockItem({
    required this.ingredient,
    required this.reason,
    required this.urgency,
  });
}

// -- Static flavor knowledge ---------------------------------------------------

// Fallback flavor profiles for ingredients that don't have them set yet
const _barDefaults = <String, (String cat, List<String> flavors)>{
  'dark rum': ('spirit', ['tropical', 'sweet', 'funky', 'rich']),
  'light rum': ('spirit', ['tropical', 'fresh', 'sweet']),
  'white rum': ('spirit', ['fresh', 'sweet', 'light']),
  'aged rum': ('spirit', ['tropical', 'sweet', 'rich', 'vanilla']),
  'spiced rum': ('spirit', ['spiced', 'sweet', 'tropical']),
  'bourbon': ('spirit', ['sweet', 'vanilla', 'caramel', 'spirit-forward']),
  'rye whiskey': ('spirit', ['spiced', 'dry', 'spirit-forward']),
  'scotch whisky': ('spirit', ['smoky', 'peaty', 'spirit-forward']),
  'irish whiskey': ('spirit', ['light', 'smooth', 'sweet']),
  'gin': ('spirit', ['herbal', 'botanical', 'fresh', 'floral', 'citrus']),
  'vodka': ('spirit', ['neutral', 'clean', 'fresh']),
  'blanco tequila': ('spirit', ['fresh', 'citrus', 'vegetal']),
  'reposado tequila': ('spirit', ['sweet', 'spiced', 'citrus']),
  'mezcal': ('spirit', ['smoky', 'earthy', 'funky']),
  'cognac': ('spirit', ['fruity', 'floral', 'rich', 'sweet']),
  'pisco': ('spirit', ['fresh', 'floral', 'fruity']),
  'triple sec': ('liqueur', ['citrus', 'sweet', 'orange']),
  'cointreau': ('liqueur', ['citrus', 'sweet', 'orange', 'floral']),
  'campari': ('liqueur', ['bitter', 'sweet', 'herbal', 'aperitif']),
  'aperol': ('liqueur', ['bitter', 'sweet', 'orange', 'aperitif']),
  'orgeat': ('syrup', ['sweet', 'nutty', 'almond', 'tropical']),
  'simple syrup': ('syrup', ['sweet', 'neutral']),
  'demerara syrup': ('syrup', ['sweet', 'rich', 'molasses']),
  'honey syrup': ('syrup', ['sweet', 'floral', 'warm']),
  'grenadine': ('syrup', ['sweet', 'fruity', 'berry']),
  'velvet falernum': ('liqueur', ['sweet', 'spiced', 'tropical', 'tiki']),
  'allspice dram': ('liqueur', ['spiced', 'warm', 'tiki']),
  'fresh lime juice': ('juice', ['sour', 'citrus', 'fresh', 'tart']),
  'fresh lemon juice': ('juice', ['sour', 'citrus', 'fresh', 'tart']),
  'pineapple juice': ('juice', ['tropical', 'sweet', 'fruity']),
  'grapefruit juice': ('juice', ['citrus', 'tart', 'bitter']),
  'orange juice': ('juice', ['sweet', 'citrus', 'fruity']),
  'angostura bitters': ('bitters', ['bitter', 'spiced', 'aromatic']),
  "peychaud's bitters": ('bitters', ['bitter', 'anise', 'floral']),
  'orange bitters': ('bitters', ['bitter', 'citrus', 'aromatic']),
  'ginger beer': ('mixer', ['spicy', 'sweet', 'fresh', 'fizzy']),
  'soda water': ('mixer', ['neutral', 'fizzy']),
  'tonic water': ('mixer', ['bitter', 'fresh', 'fizzy']),
  'prosecco': ('wine', ['light', 'fresh', 'fruity', 'fizzy']),
  'sweet vermouth': ('wine', ['sweet', 'herbal', 'bitter', 'aromatic']),
  'coconut cream': ('syrup', ['tropical', 'sweet', 'rich', 'creamy']),
  'cream of coconut': ('syrup', ['tropical', 'sweet', 'rich', 'creamy']),
};

const _pantryDefaults = <String, (String cat, List<String> flavors, List<String> cuisines)>{
  'garlic': ('vegetable', ['pungent', 'savory', 'aromatic', 'umami'], ['Italian', 'Mediterranean', 'Asian']),
  'onion': ('vegetable', ['savory', 'sweet', 'aromatic'], ['General']),
  'shallots': ('vegetable', ['sweet', 'mild', 'aromatic'], ['French', 'Asian']),
  'fresh ginger': ('vegetable', ['spicy', 'warm', 'aromatic', 'fresh'], ['Asian', 'Caribbean']),
  'extra virgin olive oil': ('oil', ['rich', 'fruity', 'savory'], ['Italian', 'Mediterranean']),
  'butter': ('dairy', ['rich', 'creamy', 'sweet'], ['French', 'European']),
  'soy sauce': ('sauce', ['salty', 'umami', 'savory', 'dark'], ['Asian']),
  'fish sauce': ('sauce', ['salty', 'umami', 'funky', 'savory'], ['Thai', 'Vietnamese']),
  'canned chopped tomatoes': ('tinned', ['sweet', 'sour', 'savory', 'umami'], ['Italian', 'Mediterranean']),
  'pasta': ('grain', ['neutral', 'starchy'], ['Italian']),
  'basmati rice': ('grain', ['neutral', 'fragrant', 'light'], ['Indian', 'Asian']),
  'coconut milk': ('tinned', ['sweet', 'rich', 'creamy', 'tropical'], ['Asian', 'Thai', 'Caribbean']),
  'eggs': ('dairy', ['rich', 'savory', 'creamy'], ['General']),
  'heavy cream': ('dairy', ['rich', 'creamy', 'sweet'], ['French']),
  'parmesan': ('dairy', ['salty', 'umami', 'nutty', 'sharp'], ['Italian']),
  'fresh basil': ('herb', ['herbal', 'sweet', 'fresh', 'aromatic'], ['Italian', 'Mediterranean']),
  'fresh parsley': ('herb', ['fresh', 'herbal', 'light'], ['Mediterranean']),
  'miso paste': ('condiment', ['umami', 'salty', 'savory', 'funky'], ['Japanese']),
  'tahini': ('condiment', ['nutty', 'bitter', 'rich'], ['Mediterranean', 'Middle Eastern']),
  'honey': ('sweetener', ['sweet', 'floral', 'warm'], ['Mediterranean']),
  'lentils (red)': ('grain', ['earthy', 'savory', 'mild'], ['Indian', 'Middle Eastern']),
  'canned chickpeas': ('tinned', ['earthy', 'savory', 'mild'], ['Mediterranean', 'Middle Eastern']),
  'dijon mustard': ('condiment', ['sharp', 'tangy', 'savory'], ['French']),
  'capers': ('condiment', ['salty', 'sour', 'briny'], ['Italian', 'Mediterranean']),
  'anchovies': ('condiment', ['salty', 'umami', 'funky', 'rich'], ['Italian', 'Mediterranean']),
};

// -- Cocktail flavor direction rules ------------------------------------------

// Preferred categories and flavor tags per desired vibe
const _vibeToFlavors = <String, List<String>>{
  'tropical': ['tropical', 'fruity', 'sweet', 'citrus'],
  'tiki': ['tropical', 'spiced', 'funky', 'sweet', 'tiki'],
  'fresh': ['fresh', 'citrus', 'light', 'herbal'],
  'citrus': ['citrus', 'sour', 'fresh', 'bright'],
  'sour': ['sour', 'tart', 'citrus', 'bright'],
  'smoky': ['smoky', 'earthy', 'funky'],
  'bitter': ['bitter', 'aperitif', 'herbal'],
  'spirit-forward': ['spirit-forward', 'rich', 'warm'],
  'floral': ['floral', 'aromatic', 'fresh', 'light'],
  'herbal': ['herbal', 'botanical', 'aromatic'],
  'spiced': ['spiced', 'warm', 'aromatic'],
  'fizzy': ['fizzy', 'fresh', 'light'],
};

// Which cocktail template to use for each vibe
const _vibeTechnique = <String, String>{
  'tropical': 'shake',
  'tiki': 'shake',
  'fresh': 'shake',
  'citrus': 'shake',
  'sour': 'shake',
  'smoky': 'stir',
  'bitter': 'build',
  'spirit-forward': 'stir',
  'floral': 'shake',
  'herbal': 'shake',
  'spiced': 'stir',
  'fizzy': 'build',
};

// Creative name parts keyed by vibe
const _vibeAdjectives = <String, List<String>>{
  'tropical': ['Tropic', 'Caribbean', 'Island', 'Tiki', 'Sunset', 'Horizon', 'Palm'],
  'tiki': ['Tiki', 'Polynesian', 'Reef', 'Aloha', 'Lagoon', 'Coral'],
  'fresh': ['Spring', 'Garden', 'Morning', 'Clear', 'Alpine', 'Crisp'],
  'citrus': ['Citrus', 'Bright', 'Zesty', 'Golden', 'Grove', 'Sunny'],
  'sour': ['Sharp', 'Nimble', 'Lively', 'Zesty', 'Perky', 'Brisk'],
  'smoky': ['Ember', 'Dusk', 'Storm', 'Dark', 'Haze', 'Shadow'],
  'bitter': ['Aperitivo', 'Dusk', 'Negroni', 'Campo', 'Piazza', 'Milano'],
  'spirit-forward': ['Classic', 'Reserve', 'Stirred', 'Old', 'Noble', 'Quiet'],
  'floral': ['Garden', 'Bloom', 'Petal', 'Meadow', 'Spring', 'Rose'],
  'herbal': ['Botanica', 'Verdant', 'Sage', 'Herbal', 'Alpine', 'Forest'],
  'spiced': ['Spiced', 'Autumn', 'Warm', 'Harvest', 'Cinnamon', 'Chai'],
  'fizzy': ['Sparkling', 'Fizzy', 'Bubbling', 'Light', 'Breezy', 'Airy'],
};

const _spiritNouns = <String, List<String>>{
  'rum': ['Sling', 'Punch', 'Fizz', 'Swizzle', 'Fix', 'Breeze'],
  'gin': ['Fizz', 'Rickey', 'Sling', 'Smash', 'Collins', 'Breeze'],
  'vodka': ['Mule', 'Cooler', 'Breeze', 'Crush', 'Fix', 'Fizz'],
  'tequila': ['Margarita', 'Paloma', 'Sour', 'Smash', 'Fizz'],
  'mezcal': ['Smash', 'Sour', 'Fix', 'Highball', 'Negroni'],
  'whiskey': ['Sour', 'Smash', 'Old Fashioned', 'Highball', 'Fix'],
  'bourbon': ['Sour', 'Smash', 'Fix', 'Old Fashioned', 'Cooler'],
  'cognac': ['Sidecar', 'Sour', 'Fix', 'Sling', 'Royale'],
  'default': ['Cooler', 'Smash', 'Fix', 'Sling', 'Punch', 'Sour'],
};

// -- Cocktail suggestion engine ------------------------------------------------

class MixologistService {
  static String _category(BarIngredient i) {
    if (i.category.isNotEmpty) return i.category;
    final lower = i.name.toLowerCase();
    return _barDefaults[lower]?.$1 ?? 'unknown';
  }

  static List<String> _flavors(BarIngredient i) {
    if (i.flavorProfiles.isNotEmpty) return i.flavorProfiles;
    final lower = i.name.toLowerCase();
    return _barDefaults[lower]?.$2 ?? [];
  }

  static int _flavorScore(List<String> ingredientFlavors, List<String> desired) {
    var score = 0;
    for (final f in ingredientFlavors) {
      if (desired.contains(f)) score++;
    }
    return score;
  }

  static String _spiritKey(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('rum')) return 'rum';
    if (lower.contains('gin')) return 'gin';
    if (lower.contains('vodka')) return 'vodka';
    if (lower.contains('tequila')) return 'tequila';
    if (lower.contains('mezcal')) return 'mezcal';
    if (lower.contains('bourbon')) return 'bourbon';
    if (lower.contains('whiskey') || lower.contains('whisky')) return 'whiskey';
    if (lower.contains('cognac') || lower.contains('brandy')) return 'cognac';
    return 'default';
  }

  static String _generateName(
      String spirit, String vibe, List<SuggestedIngredient> ingredients) {
    final adjs = _vibeAdjectives[vibe] ?? ['Classic'];
    final nouns = _spiritNouns[_spiritKey(spirit)] ?? _spiritNouns['default']!;
    // Use ingredient count as a deterministic seed so it's stable per combo
    final seed = ingredients.length % adjs.length;
    return '${adjs[seed]} ${nouns[seed % nouns.length]}';
  }

  /// MIX3: glassware choices offered in the Mixologist UI (plus Auto).
  static const glasswareOptions = <String>[
    'Auto',
    'Rocks glass',
    'Coupe',
    'Martini glass',
    'Highball glass',
    'Tiki mug',
    'Flute',
  ];

  static String _buildInstructions(
    String technique,
    List<SuggestedIngredient> ingredients, {
    String glassware = 'Rocks glass',
    int servings = 1,
  }) {
    final ingList = ingredients
        .where((i) => !i.optional)
        .map((i) => '${i.quantity}${i.unit} ${i.name}')
        .join(', ');
    final crew = servings > 1 ? ' (quantities for $servings servings)' : '';
    final serve = 'Serve in a $glassware$crew.';

    switch (technique) {
      case 'stir':
        return 'Combine $ingList in a mixing glass with ice. Stir for 30 seconds. '
            'Strain into a chilled $glassware.$crew';
      case 'build':
        return 'Fill a $glassware with ice. Add $ingList in order. Stir gently to combine.$crew';
      case 'blend':
        return 'Add $ingList to a blender with crushed ice. Blend until smooth. '
            'Pour into a $glassware.$crew';
      default:
        return 'Combine $ingList in a cocktail shaker with ice. Shake vigorously for 12 seconds. '
            'Strain into a chilled $glassware. $serve';
    }
  }

  /// Default ABV % by bar category when the catalog row has no value.
  static double _defaultAbvForCategory(String category) => switch (category) {
        'spirit' => 40.0,
        'liqueur' => 20.0,
        'wine' => 12.0,
        'bitters' => 35.0,
        'syrup' || 'juice' || 'mixer' || 'garnish' || 'rim' || 'ice' => 0.0,
        _ => 0.0,
      };

  static double _ingredientAbv(BarIngredient i) {
    if (i.alcoholByVolume != null && i.alcoholByVolume! >= 0) {
      return i.alcoholByVolume!;
    }
    return _defaultAbvForCategory(_category(i));
  }

  /// Map glassware (or Auto) + vibes → vessel name + preferred technique.
  static (String glass, String technique) _resolveGlassware({
    required String? glasswarePref,
    required List<String> vibes,
    required String vibeTechnique,
  }) {
    final pref = (glasswarePref ?? 'Auto').trim();
    if (pref.isNotEmpty && pref.toLowerCase() != 'auto') {
      final g = pref;
      final lower = g.toLowerCase();
      if (lower.contains('highball') || lower.contains('collins')) {
        return (g, 'build');
      }
      if (lower.contains('flute')) return (g, 'build');
      if (lower.contains('tiki')) return (g, 'shake');
      if (lower.contains('martini') || lower.contains('coupe')) {
        return (g, vibes.contains('spirit-forward') ? 'stir' : 'shake');
      }
      if (lower.contains('rocks') || lower.contains('old fashioned')) {
        return (g, vibes.contains('spirit-forward') ? 'stir' : vibeTechnique);
      }
      return (g, vibeTechnique);
    }

    // Auto: pick vessel from technique / vibe.
    if (vibes.contains('tiki') || vibes.contains('tropical')) {
      return ('Tiki mug', 'shake');
    }
    if (vibes.contains('fizzy')) return ('Highball glass', 'build');
    if (vibes.contains('spirit-forward') || vibeTechnique == 'stir') {
      return ('Rocks glass', 'stir');
    }
    if (vibeTechnique == 'build') return ('Highball glass', 'build');
    if (vibeTechnique == 'blend') return ('Tiki mug', 'blend');
    return ('Coupe', vibeTechnique == 'stir' ? 'stir' : 'shake');
  }

  /// Approximate finished-drink ABV % (volume-weighted, ~20% ice dilution).
  static double? estimateDrinkAbvPercent({
    required List<SuggestedIngredient> ingredients,
    required List<BarIngredient> bar,
    double dilution = 0.20,
  }) {
    final byName = {
      for (final b in bar) _normName(b.name): b,
    };
    var alcoholMl = 0.0;
    var totalMl = 0.0;
    for (final line in ingredients) {
      final unit = line.unit.toLowerCase();
      // Only liquid oz/ml contribute to ABV math; skip dashes.
      double? ml;
      if (unit == 'oz' || unit == 'fl oz') {
        ml = line.quantity * 29.5735;
      } else if (unit == 'ml') {
        ml = line.quantity;
      } else {
        continue;
      }
      if (ml <= 0) continue;
      final match = byName[_normName(line.name)] ??
          bar
              .where((b) {
                final n = _normName(b.name);
                final k = _normName(line.name);
                return n.contains(k) || k.contains(n);
              })
              .firstOrNull;
      final abv = match != null ? _ingredientAbv(match) : 0.0;
      alcoholMl += ml * (abv / 100.0);
      totalMl += ml;
    }
    if (totalMl <= 0) return null;
    final diluted = totalMl * (1.0 + dilution);
    return (alcoholMl / diluted) * 100.0;
  }

  static List<SuggestedIngredient> _scaleForServings(
    List<SuggestedIngredient> base,
    int servings,
  ) {
    if (servings <= 1) return base;
    return base
        .map((i) {
          final unit = i.unit.toLowerCase();
          // Dashes: scale more gently (min +1 per extra 2 guests).
          if (unit.contains('dash')) {
            final q = (i.quantity * servings).clamp(1.0, 99.0);
            return SuggestedIngredient(i.name, q, i.unit, optional: i.optional);
          }
          return SuggestedIngredient(
            i.name,
            _roundQty(i.quantity * servings),
            i.unit,
            optional: i.optional,
          );
        })
        .toList();
  }

  static double _roundQty(double q) {
    if (q >= 10) return double.parse(q.toStringAsFixed(1));
    // Keep friendly bar fractions.
    final snapped = (q * 4).round() / 4.0;
    return snapped;
  }

  // Spirit -> food pairing hints (BC13)
  static const _spiritFoodPairings = <String, List<String>>{
    'rum': ['Jerk chicken', 'Grilled fish', 'Tropical fruit', 'Coconut rice'],
    'gin': ['Smoked salmon', 'Light seafood', 'Cucumber salad', 'Thai dishes'],
    'vodka': ['Caviar', 'Blinis', 'Pickled vegetables', 'Smoked fish'],
    'tequila': ['Tacos', 'Ceviche', 'Guacamole', 'Grilled corn'],
    'mezcal': ['Grilled meats', 'Charred vegetables', 'Aged cheese', 'Mole'],
    'bourbon': ['BBQ ribs', 'Smoked brisket', 'Pecan pie', 'Sharp cheddar'],
    'whiskey': ['Cheese board', 'Smoked meats', 'Dark chocolate', 'Roasted nuts'],
    'cognac': ['Foie gras', 'Creamy sauces', 'Dark chocolate', 'Blue cheese'],
  };

  static List<String> foodPairings(String spiritName) =>
      _spiritFoodPairings[_spiritKey(spiritName)] ??
      ['Light snacks', 'Cheese board', 'Fresh fruit'];

  // Occasion -> extra vibes (BC14)
  static const occasionVibes = <String, List<String>>{
    'Summer': ['tropical', 'fresh', 'citrus', 'fizzy'],
    'Winter': ['spiced', 'spirit-forward', 'bitter'],
    'Date Night': ['floral', 'spirit-forward', 'herbal'],
    'BBQ': ['smoky', 'tropical', 'spiced'],
    'Game Night': ['fizzy', 'fresh', 'tiki'],
    'Christmas': ['spiced', 'bitter', 'floral'],
  };

  // -- MIX1: rank catalog recipes by missing bar/pantry ingredients ------------

  static String _normName(String name) => name.toLowerCase().trim();

  /// Stock set: in-bar + in-pantry names (normalized).
  static Set<String> stockNameSet({
    required List<BarIngredient> bar,
    required List<PantryIngredient> pantry,
  }) {
    final names = <String>{};
    for (final b in bar) {
      if (b.inMyBar) names.add(_normName(b.name));
    }
    for (final p in pantry) {
      if (p.inMyPantry) names.add(_normName(p.name));
    }
    return names;
  }

  // -- MIX2: substitute graph --------------------------------------------------

  /// Static bidirectional edges: each tuple is (a, b, confidence, note).
  /// Stored once; both directions registered in [_subGraph].
  static const _subEdges = <(String, String, double, String)>[
    // Citrus
    (
      'lime juice',
      'lemon juice',
      0.85,
      'Bright citrus swap; lemon is slightly sweeter',
    ),
    (
      'fresh lime juice',
      'fresh lemon juice',
      0.85,
      'Standard citrus substitute at sea',
    ),
    (
      'lime',
      'lemon',
      0.8,
      'Wedges or juice; adjust sweetness',
    ),
    (
      'lemon juice',
      'lime juice',
      0.85,
      'Bright citrus swap; lime is sharper',
    ),
    (
      'fresh lemon juice',
      'fresh lime juice',
      0.85,
      'Standard citrus substitute at sea',
    ),
    (
      'grapefruit juice',
      'orange juice',
      0.55,
      'Both sweet citrus; loses grapefruit bitterness',
    ),
    // Orange liqueurs
    (
      'triple sec',
      'cointreau',
      0.95,
      'Cointreau is a premium triple sec',
    ),
    (
      'cointreau',
      'triple sec',
      0.9,
      'Triple sec is the generic orange liqueur',
    ),
    (
      'triple sec',
      'orange curacao',
      0.85,
      'Orange curacao is in the same family',
    ),
    (
      'orange curacao',
      'cointreau',
      0.85,
      'Similar orange liqueur role',
    ),
    (
      'grand marnier',
      'cointreau',
      0.7,
      'Both orange; Grand Marnier is cognac-based',
    ),
    // Syrups / sweeteners
    (
      'orgeat',
      'almond syrup',
      0.9,
      'Almond syrup covers orgeat in a pinch',
    ),
    (
      'almond syrup',
      'orgeat',
      0.85,
      'Orgeat is almond syrup with orange-flower notes',
    ),
    (
      'simple syrup',
      'demerara syrup',
      0.8,
      'Richer sugar; use same volume',
    ),
    (
      'demerara syrup',
      'simple syrup',
      0.75,
      'Lighter sweetness; fine for most drinks',
    ),
    (
      'simple syrup',
      'honey syrup',
      0.7,
      'Honey adds floral notes',
    ),
    (
      'honey syrup',
      'simple syrup',
      0.7,
      'Neutral sweetener substitute',
    ),
    (
      'simple syrup',
      'agave syrup',
      0.65,
      'Works in tequila drinks especially',
    ),
    (
      'grenadine',
      'pomegranate syrup',
      0.85,
      'Same fruity-sweet role',
    ),
    // Rum family
    (
      'light rum',
      'white rum',
      0.95,
      'Same clear rum style',
    ),
    (
      'white rum',
      'light rum',
      0.95,
      'Same clear rum style',
    ),
    (
      'dark rum',
      'aged rum',
      0.8,
      'Aged/dark overlap for most tiki builds',
    ),
    (
      'aged rum',
      'dark rum',
      0.75,
      'Dark rum stands in for aged in many recipes',
    ),
    (
      'gold rum',
      'aged rum',
      0.75,
      'Similar mid-body rum',
    ),
    // Whiskey / tequila
    (
      'bourbon',
      'rye whiskey',
      0.7,
      'Rye is spicier; still a whiskey sour swap',
    ),
    (
      'rye whiskey',
      'bourbon',
      0.7,
      'Bourbon is sweeter; common Manhattan/Old Fashioned swap',
    ),
    (
      'blanco tequila',
      'reposado tequila',
      0.75,
      'Reposado is oakier; fine in most margaritas',
    ),
    (
      'reposado tequila',
      'blanco tequila',
      0.75,
      'Blanco is brighter; works in most recipes',
    ),
    // Aperitifs (weaker)
    (
      'campari',
      'aperol',
      0.55,
      'Aperol is sweeter and lighter; not a perfect bitter',
    ),
    (
      'aperol',
      'campari',
      0.5,
      'Campari is much more bitter; use less',
    ),
    // Bitters / misc
    (
      'angostura bitters',
      'aromatic bitters',
      0.9,
      'Aromatic bitters are the Angostura-style class',
    ),
    (
      'mint',
      'basil',
      0.45,
      'Herbal garnish only; changes the drink',
    ),
    (
      'egg white',
      'aquafaba',
      0.8,
      'Vegan foam; dry-shake the same way',
    ),
  ];

  /// Normalized key → list of (peerKey, confidence, note). Built once.
  static final Map<String, List<(String, double, String)>> _subGraph = () {
    final g = <String, List<(String, double, String)>>{};
    void add(String from, String to, double c, String note) {
      final a = _normName(from);
      final b = _normName(to);
      g.putIfAbsent(a, () => []).add((b, c, note));
      // Reverse with same note if not already present.
      final rev = g.putIfAbsent(b, () => []);
      if (!rev.any((e) => e.$1 == a)) {
        rev.add((a, c, note));
      }
    }

    for (final e in _subEdges) {
      add(e.$1, e.$2, e.$3, e.$4);
    }
    return g;
  }();

  /// True if [stockKey] can satisfy [neededKey] by soft name containment.
  static bool _softStockMatch(String neededKey, Set<String> stock) {
    if (stock.contains(neededKey)) return true;
    return stock.any(
      (s) => s == neededKey || s.contains(neededKey) || neededKey.contains(s),
    );
  }

  /// Display name for a normalized stock key (first matching bar/pantry label).
  static String _displayStockName(
    String stockKey,
    List<BarIngredient> bar,
    List<PantryIngredient> pantry,
  ) {
    for (final b in bar) {
      if (b.inMyBar && _normName(b.name) == stockKey) return b.name;
    }
    for (final p in pantry) {
      if (p.inMyPantry && _normName(p.name) == stockKey) return p.name;
    }
    // Soft
    for (final b in bar) {
      if (!b.inMyBar) continue;
      final n = _normName(b.name);
      if (n.contains(stockKey) || stockKey.contains(n)) return b.name;
    }
    for (final p in pantry) {
      if (!p.inMyPantry) continue;
      final n = _normName(p.name);
      if (n.contains(stockKey) || stockKey.contains(n)) return p.name;
    }
    return stockKey;
  }

  /// MIX2: best stocked substitutes for [neededName], highest confidence first.
  ///
  /// Sources (in priority order when confidence ties):
  /// 1. Static flavor graph ([_subGraph])
  /// 2. Catalog `substitute1` / `substitute2` on in-bar / in-pantry rows
  ///    (stocked item claims it can stand in for the needed name)
  static List<IngredientSubstitute> findSubstitutes({
    required String neededName,
    required List<BarIngredient> barIngredients,
    List<PantryIngredient> pantryIngredients = const [],
    double minConfidence = 0.45,
  }) {
    final needed = _normName(neededName);
    if (needed.isEmpty) return const [];

    final stock = stockNameSet(bar: barIngredients, pantry: pantryIngredients);
    // Already have it — no substitute needed.
    if (_softStockMatch(needed, stock)) return const [];

    final out = <IngredientSubstitute>[];
    final seenUsing = <String>{};

    void consider(String usingKey, double confidence, String note) {
      if (confidence < minConfidence) return;
      if (!_softStockMatch(usingKey, stock) && !stock.contains(usingKey)) {
        // usingKey may be exact stock key; also accept soft.
        if (!stock.any(
          (s) => s == usingKey || s.contains(usingKey) || usingKey.contains(s),
        )) {
          return;
        }
      }
      final usingName = _displayStockName(
        usingKey,
        barIngredients,
        pantryIngredients,
      );
      final uk = _normName(usingName);
      if (seenUsing.contains(uk)) return;
      seenUsing.add(uk);
      out.add(IngredientSubstitute(
        needed: neededName,
        using: usingName,
        confidence: confidence,
        note: note,
      ));
    }

    // 1) Static graph — match needed key and soft keys.
    void fromGraph(String key) {
      for (final edge in _subGraph[key] ?? const <(String, double, String)>[]) {
        consider(edge.$1, edge.$2, edge.$3);
      }
    }

    fromGraph(needed);
    // Soft: "fresh lime juice" also tries "lime juice", "lime".
    for (final key in _subGraph.keys) {
      if (key == needed) continue;
      if (needed.contains(key) || key.contains(needed)) {
        fromGraph(key);
      }
    }

    // 2) Catalog hierarchy: stocked bottle lists needed as substitute1/2.
    for (final b in barIngredients) {
      if (!b.inMyBar) continue;
      final s1 = b.substitute1?.toLowerCase().trim();
      final s2 = b.substitute2?.toLowerCase().trim();
      if (s1 == needed ||
          (s1 != null && (needed.contains(s1) || s1.contains(needed)))) {
        consider(
          _normName(b.name),
          0.75,
          'Catalog: ${b.name} lists ${b.substitute1} as a substitute',
        );
      }
      if (s2 == needed ||
          (s2 != null && (needed.contains(s2) || s2.contains(needed)))) {
        consider(
          _normName(b.name),
          0.65,
          'Catalog: ${b.name} lists ${b.substitute2} as a secondary substitute',
        );
      }
    }
    for (final p in pantryIngredients) {
      if (!p.inMyPantry) continue;
      final s1 = p.substitute1?.toLowerCase().trim();
      final s2 = p.substitute2?.toLowerCase().trim();
      if (s1 == needed ||
          (s1 != null && (needed.contains(s1) || s1.contains(needed)))) {
        consider(
          _normName(p.name),
          0.75,
          'Catalog: ${p.name} lists ${p.substitute1} as a substitute',
        );
      }
      if (s2 == needed ||
          (s2 != null && (needed.contains(s2) || s2.contains(needed)))) {
        consider(
          _normName(p.name),
          0.65,
          'Catalog: ${p.name} lists ${p.substitute2} as a secondary substitute',
        );
      }
    }

    out.sort((a, b) => b.confidence.compareTo(a.confidence));
    return out;
  }

  /// Best single substitute that counts toward makeable (confidence ≥ 0.6), or null.
  static IngredientSubstitute? bestCountingSubstitute({
    required String neededName,
    required List<BarIngredient> barIngredients,
    List<PantryIngredient> pantryIngredients = const [],
  }) {
    final all = findSubstitutes(
      neededName: neededName,
      barIngredients: barIngredients,
      pantryIngredients: pantryIngredients,
      minConfidence: 0.6,
    );
    return all.where((s) => s.countsAsHave).firstOrNull;
  }

  /// Rank recipes by fewest missing required ingredients (makeable first).
  ///
  /// [ingredientsByRecipeId] maps `recipe.supabaseId` → its line items.
  /// Optional ingredients and garnishes are ignored for the missing count.
  /// MIX2: missing lines with a stocked substitute (confidence ≥ 0.6) count as
  /// have and are listed in [MakeableRecipeScore.substitutesUsed].
  static List<MakeableRecipeScore> rankMakeableTonight({
    required List<Recipe> recipes,
    required Map<String, List<RecipeIngredient>> ingredientsByRecipeId,
    required List<BarIngredient> barIngredients,
    List<PantryIngredient> pantryIngredients = const [],
    int limit = 15,
  }) {
    final stock = stockNameSet(bar: barIngredients, pantry: pantryIngredients);
    final scored = <MakeableRecipeScore>[];

    for (final recipe in recipes) {
      final ings = ingredientsByRecipeId[recipe.supabaseId] ?? const [];
      final required = ings
          .where((i) => !i.isOptional && !i.isGarnish && i.name.trim().isNotEmpty)
          .toList();
      if (required.isEmpty) continue;

      final have = <String>[];
      final missing = <String>[];
      final subs = <IngredientSubstitute>[];
      for (final i in required) {
        final n = _normName(i.name);
        if (_softStockMatch(n, stock)) {
          have.add(i.name);
          continue;
        }
        final sub = bestCountingSubstitute(
          neededName: i.name,
          barIngredients: barIngredients,
          pantryIngredients: pantryIngredients,
        );
        if (sub != null && sub.countsAsHave) {
          have.add(i.name);
          subs.add(sub);
        } else {
          missing.add(i.name);
        }
      }

      scored.add(MakeableRecipeScore(
        recipe: recipe,
        haveCount: have.length,
        missingCount: missing.length,
        haveNames: have,
        missingNames: missing,
        substitutesUsed: subs,
      ));
    }

    scored.sort((a, b) {
      final byMissing = a.missingCount.compareTo(b.missingCount);
      if (byMissing != 0) return byMissing;
      // Prefer fewer substitutes among fully makeable (true stock over swaps).
      if (a.missingCount == 0 && b.missingCount == 0) {
        final bySubs =
            a.substitutesUsed.length.compareTo(b.substitutesUsed.length);
        if (bySubs != 0) return bySubs;
      }
      final byHave = b.haveCount.compareTo(a.haveCount);
      if (byHave != 0) return byHave;
      return a.recipe.name.toLowerCase().compareTo(b.recipe.name.toLowerCase());
    });

    if (scored.length <= limit) return scored;
    return scored.sublist(0, limit);
  }

  // -- MIX4: bar low-stock / stale purchase signals ----------------------------

  /// Flag in-bar bottles that look depleted or overdue for restock.
  ///
  /// Signals (higher urgency first):
  /// - in bar, never purchased, lastModified older than [neverBoughtStaleDays]
  /// - last purchase older than [staleDays]
  static List<BarLowStockItem> lowStockBarItems({
    required List<BarIngredient> barIngredients,
    int staleDays = 90,
    int neverBoughtStaleDays = 120,
    DateTime? now,
  }) {
    final at = now ?? DateTime.now().toUtc();
    final out = <BarLowStockItem>[];

    for (final i in barIngredients) {
      if (!i.inMyBar) continue;

      DateTime? lastBuy;
      for (final p in i.purchaseHistory) {
        final d = p.purchaseDate?.toUtc();
        if (d == null) continue;
        if (lastBuy == null || d.isAfter(lastBuy)) lastBuy = d;
      }

      if (lastBuy == null) {
        final age = at.difference(i.lastModified.toUtc()).inDays;
        if (age >= neverBoughtStaleDays) {
          out.add(BarLowStockItem(
            ingredient: i,
            reason: 'In bar $age days, no purchase on record',
            urgency: 50 + (age ~/ 30),
          ));
        }
        continue;
      }

      final days = at.difference(lastBuy).inDays;
      if (days >= staleDays) {
        out.add(BarLowStockItem(
          ingredient: i,
          reason: 'Last purchase $days days ago',
          urgency: 100 + (days ~/ 10),
        ));
      }
    }

    out.sort((a, b) => b.urgency.compareTo(a.urgency));
    return out;
  }

  // Main cocktail suggestion method
  ///
  /// MIX3: [strength] scales spirit vs mixer, [glassware] constrains vessel /
  /// technique (`Auto` or null picks from vibes), [servings] multiplies pours
  /// for crew size. Estimated ABV is approximate (includes ~20% dilution).
  static CocktailSuggestion? suggest({
    required List<String> vibes,
    required List<BarIngredient> barIngredients,
    CocktailStrength strength = CocktailStrength.session,
    String? glassware,
    int servings = 1,
  }) {
    final available = barIngredients.where((i) => i.inMyBar).toList();
    if (available.isEmpty) return null;

    final crew = servings < 1 ? 1 : (servings > 12 ? 12 : servings);

    // Build desired flavor list from vibes
    final desiredFlavors = <String>{};
    for (final v in vibes) {
      desiredFlavors.addAll(_vibeToFlavors[v] ?? []);
    }
    if (desiredFlavors.isEmpty) {
      desiredFlavors.addAll(['fresh', 'citrus', 'sweet']);
    }

    final vibeTechnique = _vibeTechnique[vibes.firstOrNull] ?? 'shake';
    final resolved = _resolveGlassware(
      glasswarePref: glassware,
      vibes: vibes,
      vibeTechnique: vibeTechnique,
    );
    final technique = resolved.$2;
    final glass = resolved.$1;
    final desiredList = desiredFlavors.toList();

    // Categorise available ingredients
    final spirits = available.where((i) => _category(i) == 'spirit').toList();
    final juices = available.where((i) => _category(i) == 'juice').toList();
    final syrups = available.where((i) => _category(i) == 'syrup').toList();
    final liqueurs = available.where((i) => _category(i) == 'liqueur').toList();
    final bitters = available.where((i) => _category(i) == 'bitters').toList();
    final mixers = available.where((i) => _category(i) == 'mixer').toList();

    if (spirits.isEmpty) return null; // Need at least a spirit

    // Score spirits by vibe; MIX3 also bias ABV for light vs strong.
    spirits.sort((a, b) {
      final byFlavor = _flavorScore(_flavors(b), desiredList)
          .compareTo(_flavorScore(_flavors(a), desiredList));
      if (byFlavor != 0) return byFlavor;
      final abvA = _ingredientAbv(a);
      final abvB = _ingredientAbv(b);
      return switch (strength) {
        CocktailStrength.light => abvA.compareTo(abvB), // lower ABV first
        CocktailStrength.strong => abvB.compareTo(abvA), // higher first
        CocktailStrength.session => 0,
      };
    });
    final spirit = spirits.first;

    // Select acid - prefer sour/citrus juices that match vibe
    final acids = juices.where((j) {
      final f = _flavors(j);
      return f.contains('sour') || f.contains('citrus') || f.contains('tart');
    }).toList();
    acids.sort((a, b) =>
        _flavorScore(_flavors(b), desiredList)
            .compareTo(_flavorScore(_flavors(a), desiredList)));

    // Select sweet - prefer syrups matching vibe
    final sweets = [...syrups];
    sweets.addAll(liqueurs.where((l) => _flavors(l).contains('sweet')));
    sweets.sort((a, b) =>
        _flavorScore(_flavors(b), desiredList)
            .compareTo(_flavorScore(_flavors(a), desiredList)));

    // Select modifier - optional liqueur that adds complexity
    final modifiers = liqueurs
        .where((l) => l != (sweets.firstOrNull))
        .toList();
    modifiers.sort((a, b) =>
        _flavorScore(_flavors(b), desiredList)
            .compareTo(_flavorScore(_flavors(a), desiredList)));

    // Select fizz for build/fizzy vibes / highball glassware
    BarIngredient? fizz;
    final wantFizz = technique == 'build' ||
        vibes.contains('fizzy') ||
        glass.toLowerCase().contains('highball') ||
        glass.toLowerCase().contains('flute');
    if (wantFizz) {
      final fizzOpts = mixers
          .where((m) => _flavors(m).contains('fizzy'))
          .toList();
      fizzOpts.sort((a, b) =>
          _flavorScore(_flavors(b), desiredList)
              .compareTo(_flavorScore(_flavors(a), desiredList)));
      fizz = fizzOpts.firstOrNull;
    }

    // Select bitters - optional
    final bitter = bitters.firstOrNull;

    final spiritOz = strength.spiritOz;
    final balanceOz = strength.balanceOz;
    // Tiki / highball: slightly larger balance pours.
    final balanceScale =
        glass.toLowerCase().contains('tiki') || technique == 'build' ? 1.15 : 1.0;
    final bal = _roundQty(balanceOz * balanceScale);
    final modOz = strength == CocktailStrength.strong ? 0.75 : 0.5;
    final fizzOz = strength == CocktailStrength.light ? 3.0 : 2.0;

    // Build single-serving list, then scale for crew.
    final single = <SuggestedIngredient>[
      SuggestedIngredient(spirit.name, spiritOz, 'oz'),
    ];

    if (acids.isNotEmpty) {
      single.add(SuggestedIngredient(acids.first.name, bal, 'oz'));
    }

    if (sweets.isNotEmpty) {
      single.add(SuggestedIngredient(sweets.first.name, bal, 'oz'));
    }

    if (modifiers.isNotEmpty && modifiers.first != sweets.firstOrNull) {
      // Strong drinks keep modifiers; light drops them unless high confidence vibe.
      if (strength != CocktailStrength.light) {
        single.add(SuggestedIngredient(
            modifiers.first.name, modOz, 'oz',
            optional: true));
      }
    }

    if (fizz != null) {
      single.add(SuggestedIngredient(fizz.name, fizzOz, 'oz'));
    }

    if (bitter != null) {
      single.add(SuggestedIngredient(bitter.name, 2.0, 'dashes', optional: true));
    }

    final ingredients = _scaleForServings(single, crew);

    final name =
        _generateName(spirit.name, vibes.firstOrNull ?? 'fresh', ingredients);

    final abv = estimateDrinkAbvPercent(
      ingredients: ingredients,
      bar: available,
    );

    final vibeLabel = vibes.isEmpty ? 'fresh' : vibes.join(', ');
    final abvNote = abv == null
        ? ''
        : ' About ${abv.toStringAsFixed(0)}% ABV est.';
    final rationale =
        'Built around ${spirit.name} for a ${strength.label.toLowerCase()} '
        '$vibeLabel pour in a $glass.'
        '${acids.isNotEmpty ? " ${acids.first.name} adds brightness." : ""}'
        '${sweets.isNotEmpty ? " ${sweets.first.name} balances sweetness." : ""}'
        '${crew > 1 ? " Scaled for $crew." : ""}'
        '$abvNote';

    return CocktailSuggestion(
      name: name,
      ingredients: ingredients,
      instructions: _buildInstructions(
        technique,
        ingredients,
        glassware: glass,
        servings: crew,
      ),
      rationale: rationale,
      technique: technique,
      glassware: glass,
      strengthLabel: strength.label,
      servings: crew,
      estimatedAbvPercent: abv,
    );
  }

  // -- Dish suggestion engine --------------------------------------------------

  static String _pantryCategory(PantryIngredient i) {
    if (i.category.isNotEmpty) return i.category;
    final lower = i.name.toLowerCase();
    return _pantryDefaults[lower]?.$1 ?? 'unknown';
  }

  static List<String> _pantryFlavors(PantryIngredient i) {
    if (i.flavorProfiles.isNotEmpty) return i.flavorProfiles;
    final lower = i.name.toLowerCase();
    return _pantryDefaults[lower]?.$2 ?? [];
  }

  static const _cuisineVibes = <String, List<String>>{
    'italian': ['savory', 'umami', 'herbal', 'rich'],
    'asian': ['umami', 'savory', 'spicy', 'aromatic'],
    'mediterranean': ['savory', 'fresh', 'herbal', 'briny'],
    'light': ['fresh', 'light', 'herbal', 'bright'],
    'hearty': ['rich', 'savory', 'earthy', 'warm'],
    'comfort': ['rich', 'creamy', 'warm', 'savory'],
    'fresh': ['fresh', 'light', 'herbal', 'bright'],
    'spicy': ['spicy', 'hot', 'pungent', 'aromatic'],
    'umami': ['umami', 'savory', 'funky', 'rich'],
    'sweet & savory': ['sweet', 'savory', 'caramel', 'warm'],
  };

  static const _cuisineTemplates = <String, String>{
    'italian': 'Italian',
    'asian': 'Asian',
    'mediterranean': 'Mediterranean',
    'light': 'Light',
    'hearty': 'Hearty',
    'comfort': 'Comfort',
    'fresh': 'Fresh',
    'spicy': 'Spiced',
    'umami': 'Umami-Rich',
    'sweet & savory': 'Sweet & Savory',
  };

  // -- MIX5: leftover / use-soon scoring ---------------------------------------

  /// Pure priority score for one pantry row (higher = use sooner).
  ///
  /// Combines flavour match to [desiredFlavors] (optional), expiry urgency,
  /// low quantity, protein bias, and stale in-pantry stock without an expiry.
  static int pantryPriorityScore(
    PantryIngredient i, {
    List<String> desiredFlavors = const [],
    DateTime? now,
  }) {
    final at = now ?? DateTime.now();
    var score = 0;
    if (desiredFlavors.isNotEmpty) {
      score += _flavorScore(_pantryFlavors(i), desiredFlavors);
    }

    final exp = i.expiryDate;
    if (exp != null) {
      final days = exp.difference(at).inDays;
      if (days < 0) {
        score += 200; // already past date — cook or bin
      } else if (days <= 1) {
        score += 150;
      } else if (days <= 3) {
        score += 120;
      } else if (days <= 7) {
        score += 100;
      } else if (days <= 14) {
        score += 40;
      }
    } else {
      // No expiry on file: mild nudge if it's been sitting a while.
      final age = at.difference(i.lastModified).inDays;
      if (age >= 45) {
        score += 25;
      } else if (age >= 21) {
        score += 12;
      }
    }

    final q = i.quantity;
    if (q != null) {
      if (q <= 0) {
        score += 5; // empty-ish marker
      } else if (q <= 1) {
        score += 35; // last scrap — use it
      } else if (q <= 3) {
        score += 15;
      }
    }

    final cat = _pantryCategory(i);
    if (cat == 'protein') score += 15;
    if (cat == 'dairy' || cat == 'fruit' || cat == 'vegetable') score += 8;

    return score;
  }

  /// Rank in-pantry items for leftover / use-soon (MIX5).
  ///
  /// Skips allergen / dietary filters unless provided. Returns highest score
  /// first; items with score ≤ 0 are omitted unless [includeZero] is true.
  static List<PantryPriorityItem> rankPantryForLeftovers({
    required List<PantryIngredient> pantryIngredients,
    List<String> desiredFlavors = const [],
    List<String> allergenRestrictions = const [],
    List<String> dietaryRequirements = const [],
    DateTime? now,
    int limit = 20,
    bool includeZero = false,
  }) {
    var available = pantryIngredients.where((i) => i.inMyPantry).toList();
    if (allergenRestrictions.isNotEmpty) {
      available = available
          .where((i) =>
              i.allergenTags.every((a) => !allergenRestrictions.contains(a)))
          .toList();
    }
    if (dietaryRequirements.isNotEmpty) {
      available = available
          .where((i) =>
              dietaryRequirements.every((d) => i.dietaryTags.contains(d)))
          .toList();
    }

    final at = now ?? DateTime.now();
    final ranked = <PantryPriorityItem>[];
    for (final i in available) {
      final s = pantryPriorityScore(
        i,
        desiredFlavors: desiredFlavors,
        now: at,
      );
      if (!includeZero && s <= 0) continue;
      ranked.add(PantryPriorityItem(
        ingredient: i,
        score: s,
        reasons: _leftoverReasons(i, at),
      ));
    }
    ranked.sort((a, b) {
      final byScore = b.score.compareTo(a.score);
      if (byScore != 0) return byScore;
      return a.ingredient.name
          .toLowerCase()
          .compareTo(b.ingredient.name.toLowerCase());
    });
    if (ranked.length <= limit) return ranked;
    return ranked.sublist(0, limit);
  }

  static List<String> _leftoverReasons(PantryIngredient i, DateTime at) {
    final reasons = <String>[];
    final exp = i.expiryDate;
    if (exp != null) {
      final days = exp.difference(at).inDays;
      if (days < 0) {
        reasons.add('Past expiry (${-days}d)');
      } else if (days == 0) {
        reasons.add('Expires today');
      } else if (days == 1) {
        reasons.add('Expires tomorrow');
      } else if (days <= 7) {
        reasons.add('Expires in $days days');
      } else if (days <= 14) {
        reasons.add('Use within 2 weeks');
      }
    } else {
      final age = at.difference(i.lastModified).inDays;
      if (age >= 21) reasons.add('In pantry ${age}d (no expiry set)');
    }
    final q = i.quantity;
    if (q != null && q > 0 && q <= 1) {
      reasons.add('Low quantity ($q${i.unit != null ? ' ${i.unit}' : ''})');
    } else if (q != null && q > 1 && q <= 3) {
      reasons.add('Running low');
    }
    if (_pantryCategory(i) == 'protein') reasons.add('Protein — use soon');
    if (reasons.isEmpty) reasons.add('In pantry');
    return reasons;
  }

  static DishSuggestion? suggestDish({
    required List<String> vibes,
    required List<PantryIngredient> pantryIngredients,
    List<String> allergenRestrictions = const [],
    List<String> dietaryRequirements = const [],
    DateTime? now,
  }) {
    var available = pantryIngredients.where((i) => i.inMyPantry).toList();
    // Exclude ingredients that contain a restricted allergen
    if (allergenRestrictions.isNotEmpty) {
      available = available
          .where((i) => i.allergenTags.every((a) => !allergenRestrictions.contains(a)))
          .toList();
    }
    // Exclude ingredients that don't satisfy required dietary tags (if any)
    if (dietaryRequirements.isNotEmpty) {
      available = available
          .where((i) => dietaryRequirements.every((d) => i.dietaryTags.contains(d)))
          .toList();
    }
    if (available.isEmpty) return null;

    final at = now ?? DateTime.now();
    final primaryVibe = vibes.firstOrNull ?? 'hearty';
    final desiredFlavors = <String>{};
    for (final v in vibes) {
      desiredFlavors.addAll(_cuisineVibes[v.toLowerCase()] ?? []);
    }
    if (desiredFlavors.isEmpty) {
      desiredFlavors.addAll(['savory', 'rich', 'warm']);
    }
    final desiredList = desiredFlavors.toList();
    final cuisineLabel = _cuisineTemplates[primaryVibe.toLowerCase()] ?? 'Sailor';

    int score(PantryIngredient i) => pantryPriorityScore(
          i,
          desiredFlavors: desiredList,
          now: at,
        );

    // Categorise (then rank each bucket by leftover + vibe score).
    final proteins = available
        .where((i) => ['protein', 'dairy'].contains(_pantryCategory(i)) &&
            _pantryFlavors(i).any((f) => ['savory', 'rich', 'umami'].contains(f)))
        .toList()
      ..sort((a, b) => score(b).compareTo(score(a)));
    final grains = available.where((i) => _pantryCategory(i) == 'grain').toList()
      ..sort((a, b) => score(b).compareTo(score(a)));
    final oils = available.where((i) => _pantryCategory(i) == 'oil').toList()
      ..sort((a, b) => score(b).compareTo(score(a)));
    final aromatics = available
        .where((i) =>
            _pantryCategory(i) == 'vegetable' &&
            _pantryFlavors(i).any((f) => ['pungent', 'aromatic', 'savory'].contains(f)))
        .toList()
      ..sort((a, b) => score(b).compareTo(score(a)));
    final sauces = available
        .where((i) => ['sauce', 'condiment', 'tinned'].contains(_pantryCategory(i)))
        .toList()
      ..sort((a, b) => score(b).compareTo(score(a)));
    final herbs = available.where((i) => _pantryCategory(i) == 'herb').toList()
      ..sort((a, b) => score(b).compareTo(score(a)));
    final seasonings =
        available.where((i) => _pantryCategory(i) == 'seasoning').toList();
    final produce = available
        .where((i) =>
            ['vegetable', 'fruit'].contains(_pantryCategory(i)) &&
            !aromatics.contains(i))
        .toList()
      ..sort((a, b) => score(b).compareTo(score(a)));

    final dishIngredients = <SuggestedIngredient>[];
    final usedNames = <String>{};

    void addLine(PantryIngredient i, double qty, String unit,
        {bool optional = false}) {
      final key = i.name.toLowerCase();
      if (usedNames.contains(key)) return;
      usedNames.add(key);
      dishIngredients
          .add(SuggestedIngredient(i.name, qty, unit, optional: optional));
    }

    // Base oil or butter
    if (oils.isNotEmpty) {
      addLine(oils.first, 2.0, 'tbsp');
    }

    // Primary aromatic
    if (aromatics.isNotEmpty) {
      addLine(aromatics.first, 1.0, 'clove/piece');
      if (aromatics.length > 1) {
        addLine(aromatics[1], 1.0, 'piece');
      }
    }

    // Protein or main ingredient (highest leftover priority wins)
    if (proteins.isNotEmpty) {
      addLine(proteins.first, 200.0, 'g');
    }

    // Grain / starch
    if (grains.isNotEmpty) {
      final grain = grains.first;
      final qty = grain.name.toLowerCase().contains('rice') ? 150.0 : 200.0;
      addLine(grain, qty, 'g');
    }

    // Sauce or tins
    if (sauces.isNotEmpty) {
      addLine(sauces.first, 1.0, 'can/jar');
      if (sauces.length > 1) {
        addLine(sauces[1], 1.0, 'tbsp', optional: true);
      }
    }

    // MIX5: fold in top leftover produce not already on the plate.
    for (final p in produce.take(3)) {
      if (score(p) < 40) break; // only meaningful leftover pressure
      addLine(p, 1.0, 'portion', optional: score(p) < 100);
    }

    // Herbs
    if (herbs.isNotEmpty) {
      addLine(herbs.first, 1.0, 'handful', optional: true);
    }

    // Seasonings
    final salt =
        seasonings.where((s) => s.name.toLowerCase().contains('salt')).firstOrNull;
    final pepper = seasonings
        .where((s) => s.name.toLowerCase().contains('pepper'))
        .firstOrNull;
    if (salt != null) addLine(salt, 0.0, 'to taste');
    if (pepper != null) addLine(pepper, 0.0, 'to taste');

    if (dishIngredients.isEmpty) return null;

    // Leftover notes for UI (top urgent items that appear on the plate).
    final priority = rankPantryForLeftovers(
      pantryIngredients: available,
      desiredFlavors: desiredList,
      now: at,
      limit: 8,
      includeZero: true,
    );
    final onPlate = usedNames;
    final leftoverNotes = <String>[];
    for (final p in priority) {
      if (!onPlate.contains(p.ingredient.name.toLowerCase())) continue;
      if (p.score < 40) continue;
      final why = p.reasons.isEmpty ? 'priority' : p.reasons.first;
      leftoverNotes.add('${p.ingredient.name}: $why');
      if (leftoverNotes.length >= 4) break;
    }

    // Name: prefer leftover hero (expiring protein/produce) over bland label.
    final hero = priority
        .where((p) => onPlate.contains(p.ingredient.name.toLowerCase()))
        .where((p) => p.score >= 100)
        .map((p) => p.ingredient)
        .firstOrNull;
    final proteinLabel = proteins.isNotEmpty
        ? proteins.first.name
        : (hero?.name ?? 'Pantry');
    final dishName = hero != null && hero != proteins.firstOrNull
        ? '$cuisineLabel ${hero.name.split(' ').last} Skillet'
        : '$cuisineLabel ${proteinLabel.split(' ').last}';

    final grainLabel =
        grains.isNotEmpty ? ' Serve with ${grains.first.name}.' : '';
    final useSoonLine = leftoverNotes.isEmpty
        ? ''
        : 'Prioritise: ${leftoverNotes.take(2).map((n) => n.split(':').first).join(', ')}. ';
    final instructions =
        'Heat oil in a pan over medium heat. Saute aromatics until fragrant, about 2 minutes. '
        'Add main ingredients and cook through, about 8-12 minutes. '
        'Add sauce and simmer for 5 minutes. Season to taste. '
        '${herbs.isNotEmpty ? "Finish with fresh ${herbs.first.name}. " : ""}'
        '$useSoonLine'
        '$grainLabel';

    final vibeLabel = vibes.isEmpty ? 'pantry' : vibes.join(', ');
    final rationale = leftoverNotes.isNotEmpty
        ? 'Built to clear leftovers first: ${leftoverNotes.take(2).join('; ')}. '
            'A $vibeLabel dish from what\'s already aboard.'
        : 'A $vibeLabel dish built from what\'s in your pantry. '
            '${aromatics.isNotEmpty ? "${aromatics.first.name} builds the aromatic base. " : ""}'
            '${sauces.isNotEmpty ? "${sauces.first.name} adds depth and character." : ""}';

    return DishSuggestion(
      name: dishName,
      ingredients: dishIngredients,
      instructions: instructions,
      rationale: rationale,
      cuisine: cuisineLabel,
      leftoverNotes: leftoverNotes,
    );
  }
}
