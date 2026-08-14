import 'package:flutter_test/flutter_test.dart';
import 'package:sisu_mate/data/seed/ingredient_aliases.dart';
import 'package:sisu_mate/data/seed/seed_bar_ingredients.dart';
import 'package:sisu_mate/data/seed/seed_pantry_ingredients.dart';

void main() {
  final catalog = {
    for (final p in bundledPantryIngredients()) p.name.toLowerCase(),
    for (final b in bundledBarIngredients()) b.name.toLowerCase(),
  };

  test('#331 aliases resolve to pantry or bar catalog names', () {
    const samples = {
      'Beef mince': 'Ground Beef',
      'Egg': 'Eggs',
      'Olive Oil': 'Extra Virgin Olive Oil',
      'London Dry Gin': 'Gin',
      'Tequila': 'Blanco Tequila',
      'White Rum': 'White Blended Rum',
      'Prime Ribeye Steak': 'Ribeye Steak',
      'Fresh Sea Bass': 'Sea Bass',
    };
    for (final e in samples.entries) {
      final got = canonicalIngredientName(e.key);
      expect(got, e.value, reason: e.key);
      expect(catalog, contains(got.toLowerCase()), reason: got);
    }
  });
}
