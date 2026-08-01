import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:sisu_mate/models/models.dart';
import 'package:sisu_mate/services/recipe_share_service.dart';

bool _isPdf(Uint8List bytes) =>
    bytes.length > 4 &&
    String.fromCharCodes(bytes.sublist(0, 4)) == '%PDF';

void main() {
  group('RecipeShareService.formatIngredient', () {
    test('formats quantity, unit, flags', () {
      final i = RecipeIngredient()
        ..name = 'Rum'
        ..quantity = 2
        ..unit = 'oz'
        ..isOptional = true
        ..isGarnish = true;
      expect(
        RecipeShareService.formatIngredient(i),
        '2 oz Rum (optional) (garnish)',
      );
    });

    test('keeps fractional quantities', () {
      final i = RecipeIngredient()
        ..name = 'Lime'
        ..quantity = 0.5
        ..unit = 'oz';
      expect(RecipeShareService.formatIngredient(i), '0.5 oz Lime');
    });

    test('name-only when quantity/unit missing', () {
      final i = RecipeIngredient()..name = 'Ice';
      expect(RecipeShareService.formatIngredient(i), 'Ice');
    });
  });

  group('RecipeShareService.buildRecipeCardPdf', () {
    test('produces a valid PDF for a full cocktail card', () async {
      final recipe = Recipe()
        ..name = 'Mai Tai'
        ..cuisine = ['Tiki', 'Classic']
        ..description = 'A tiki classic'
        ..prepMinutes = 5
        ..cookMinutes = 0
        ..glassware = 'Double rocks'
        ..instructions = 'Shake and strain.';
      final ingredients = [
        RecipeIngredient()
          ..name = 'Rum'
          ..quantity = 2
          ..unit = 'oz',
        RecipeIngredient()
          ..name = 'Mint'
          ..isGarnish = true,
      ];

      final bytes =
          await RecipeShareService.buildRecipeCardPdf(recipe, ingredients);
      expect(_isPdf(bytes), isTrue);
    });

    test('handles a minimal recipe without throwing', () async {
      final recipe = Recipe()..name = 'Plain Water';
      final bytes = await RecipeShareService.buildRecipeCardPdf(recipe, []);
      expect(_isPdf(bytes), isTrue);
    });
  });
}
