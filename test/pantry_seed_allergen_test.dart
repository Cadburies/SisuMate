import 'package:flutter_test/flutter_test.dart';
import 'package:sisu_mate/data/seed/seed_bar_ingredients.dart';
import 'package:sisu_mate/data/seed/seed_pantry_ingredients.dart';
import 'package:sisu_mate/models/models.dart';
import 'package:sisu_mate/services/recipe_allergen_service.dart';

void main() {
  late final byName = {
    for (final p in bundledPantryIngredients()) p.name: p,
  };

  test('#330 named allergen rows', () {
    expect(byName['Mayonnaise']!.allergenTags, contains('eggs'));
    expect(byName['Mayonnaise']!.dietaryTags, isNot(contains('vegan')));
    expect(byName['Sesame Seeds']!.allergenTags, ['sesame']);
    expect(byName['Sesame Seeds']!.allergenTags, isNot(contains('nuts')));
    expect(byName['Sesame Seeds']!.category, 'seasoning');
    expect(byName['Celery']!.allergenTags, contains('celery'));
    expect(byName['Celery Seed']!.allergenTags, contains('celery'));
    expect(byName['Yellow Mustard']!.allergenTags, contains('mustard'));
    expect(byName['Croutons']!.allergenTags, contains('gluten'));
    expect(byName['Ladyfingers']!.allergenTags, containsAll(['gluten', 'eggs']));
    expect(byName['Brioche']!.allergenTags, containsAll(['gluten', 'eggs', 'dairy']));
    expect(byName['Puff Pastry']!.allergenTags, containsAll(['gluten', 'dairy']));
    expect(byName['Caesar Dressing']!.allergenTags,
        containsAll(['fish', 'eggs', 'dairy']));
    expect(byName['Chocolate Chips']!.allergenTags, contains('dairy'));
    expect(byName['Tennis Biscuits']!.allergenTags, containsAll(['gluten', 'dairy']));
  });

  test('#330 no meat row is vegan or vegetarian', () {
    for (final name in ['Ground Beef', 'Bacon', 'Chicken Breast', 'Boerewors']) {
      final d = byName[name]!.dietaryTags;
      expect(d, isNot(contains('vegan')), reason: name);
      expect(d, isNot(contains('vegetarian')), reason: name);
    }
  });

  test('#333 seeded bar allergens for orgeat, egg white, Baileys', () {
    final bar = {for (final b in bundledBarIngredients()) b.name: b};
    expect(bar['Orgeat']!.allergenTags, contains('nuts'));
    expect(bar['Egg White']!.allergenTags, contains('eggs'));
    expect(bar['Baileys Irish Cream']!.allergenTags, contains('dairy'));
    final maiTai = [
      RecipeIngredient()..name = 'Orgeat',
      RecipeIngredient()..name = 'White Blended Rum',
    ];
    final assessment = RecipeAllergenService.assess(
      maiTai,
      const [],
      bar: bundledBarIngredients(),
    );
    expect(assessment.allergens, contains('nuts'));
  });

  test('#330 sweet/coffee/fish rows are not savory-only', () {
    for (final name in [
      'Apricot Jam',
      'Cocoa Powder',
      'Chocolate Chips',
      'Coffee',
      'Peach Puree',
      'Salmon',
      'Tuna',
    ]) {
      expect(byName[name]!.flavorProfiles, isNot(['savory']), reason: name);
    }
  });
}
