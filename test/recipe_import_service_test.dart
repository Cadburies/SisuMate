import 'package:flutter_test/flutter_test.dart';
import 'package:sisu_mate/services/recipe_import_service.dart';

String _pageWith(String jsonLd) => '''
<html><head>
<script type="application/ld+json">
$jsonLd
</script>
</head><body></body></html>
''';

void main() {
  group('RecipeImportService.parseHtml', () {
    test('parses a plain schema.org Recipe object', () {
      final html = _pageWith('''
      {
        "@context": "https://schema.org",
        "@type": "Recipe",
        "name": "Mediterranean Seafood Feast",
        "description": "Elegant seafood dinner",
        "recipeCuisine": "Mediterranean",
        "prepTime": "PT30M",
        "cookTime": "PT1H15M",
        "recipeIngredient": ["6 fillets Fresh Sea Bass", "1 lb Calamari", "Salt to taste"],
        "recipeInstructions": "Sear the bass. Serve warm."
      }
      ''');

      final parsed = RecipeImportService.parseHtml(html);

      expect(parsed.recipe.name, 'Mediterranean Seafood Feast');
      expect(parsed.recipe.description, 'Elegant seafood dinner');
      expect(parsed.recipe.cuisine, ['Mediterranean']);
      expect(parsed.recipe.prepMinutes, 30);
      expect(parsed.recipe.cookMinutes, 75);
      expect(parsed.recipe.instructions, 'Sear the bass. Serve warm.');
      expect(parsed.recipe.recipeType, 'menu');

      expect(parsed.ingredients, hasLength(3));
      expect(parsed.ingredients[0].quantity, 6);
      expect(parsed.ingredients[0].unit, 'fillets');
      expect(parsed.ingredients[0].name, 'Fresh Sea Bass');
      // 1 lb → ~454 g (metric storage)
      expect(parsed.ingredients[1].quantity, closeTo(453.6, 0.2));
      expect(parsed.ingredients[1].unit, 'g');
      expect(parsed.ingredients[1].name, 'Calamari');
      // No leading quantity — falls back to the full line as the name.
      expect(parsed.ingredients[2].quantity, isNull);
      expect(parsed.ingredients[2].name, 'Salt to taste');
    });

    test('finds the Recipe node inside an @graph array', () {
      final html = _pageWith('''
      {
        "@context": "https://schema.org",
        "@graph": [
          {"@type": "WebPage", "name": "Some Blog Post"},
          {"@type": "Recipe", "name": "Mai Tai", "recipeIngredient": ["2 oz White Rum"]}
        ]
      }
      ''');

      final parsed = RecipeImportService.parseHtml(html);

      expect(parsed.recipe.name, 'Mai Tai');
      // 2 fl oz → ~59 ml
      expect(parsed.ingredients.single.quantity, closeTo(59.15, 0.2));
      expect(parsed.ingredients.single.unit, 'ml');
      expect(parsed.ingredients.single.name, 'White Rum');
    });

    test('flattens HowToStep list instructions with numbering', () {
      final html = _pageWith('''
      {
        "@type": "Recipe",
        "name": "Test Dish",
        "recipeInstructions": [
          {"@type": "HowToStep", "text": "Chop the vegetables."},
          {"@type": "HowToStep", "text": "Fry until golden."}
        ]
      }
      ''');

      final parsed = RecipeImportService.parseHtml(html);

      expect(parsed.recipe.instructions, '1. Chop the vegetables.\n2. Fry until golden.');
    });

    test('flags optional and garnish ingredients from wording', () {
      final html = _pageWith('''
      {
        "@type": "Recipe",
        "name": "Test Dish",
        "recipeIngredient": ["1 sprig Fresh Mint (garnish)", "0.5 cup Cream, optional"]
      }
      ''');

      final parsed = RecipeImportService.parseHtml(html);

      expect(parsed.ingredients[0].isGarnish, isTrue);
      expect(parsed.ingredients[1].isOptional, isTrue);
    });

    test('recognizes spelled-out units, not just abbreviations', () {
      final html = _pageWith('''
      {
        "@type": "Recipe",
        "name": "Test Dish",
        "recipeIngredient": [
          "2 teaspoons vanilla extract",
          "1 tablespoon olive oil",
          "8 ounces shiitake mushrooms"
        ]
      }
      ''');

      final parsed = RecipeImportService.parseHtml(html);

      // Spelled-out imperial units convert to metric on parse.
      expect(parsed.ingredients[0].quantity, 10); // 2 tsp
      expect(parsed.ingredients[0].unit, 'ml');
      expect(parsed.ingredients[0].name, 'vanilla extract');
      expect(parsed.ingredients[1].quantity, 15); // 1 tbsp
      expect(parsed.ingredients[1].unit, 'ml');
      expect(parsed.ingredients[1].name, 'olive oil');
      expect(parsed.ingredients[2].quantity, closeTo(236.6, 0.2)); // 8 fl oz
      expect(parsed.ingredients[2].unit, 'ml');
      expect(parsed.ingredients[2].name, 'shiitake mushrooms');
    });

    test('throws when the page has no JSON-LD Recipe data', () {
      final html = '<html><head></head><body>No recipe here</body></html>';

      expect(() => RecipeImportService.parseHtml(html),
          throwsA(isA<RecipeImportException>()));
    });

    test('throws when the Recipe node has no name', () {
      final html = _pageWith('{"@type": "Recipe", "recipeIngredient": ["1 cup Sugar"]}');

      expect(() => RecipeImportService.parseHtml(html),
          throwsA(isA<RecipeImportException>()));
    });
  });
}
