import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:sisu_mate/models/models.dart';
import 'package:sisu_mate/services/import_service.dart';

void main() {
  group('ImportService.parse — envelope validation', () {
    test('rejects non-JSON', () {
      expect(() => ImportService.parse('not json'),
          throwsA(isA<ImportException>()));
    });

    test('rejects a missing version', () {
      expect(() => ImportService.parse('{"kind":"fuelLog","items":[]}'),
          throwsA(isA<ImportException>()));
    });

    test('rejects a future format version', () {
      expect(
          () => ImportService.parse(
              '{"sisuMateImport":999,"kind":"fuelLog","items":[]}'),
          throwsA(predicate(
              (e) => e is ImportException && e.message.contains('newer'))));
    });

    test('rejects an unknown kind', () {
      expect(
          () => ImportService.parse(
              '{"sisuMateImport":1,"kind":"widgets","items":[]}'),
          throwsA(predicate((e) =>
              e is ImportException && e.message.contains('Unknown'))));
    });

    test('rejects an empty items list', () {
      expect(
          () => ImportService.parse(
              '{"sisuMateImport":1,"kind":"fuelLog","items":[]}'),
          throwsA(predicate(
              (e) => e is ImportException && e.message.contains('empty'))));
    });
  });

  group('ImportService.parse — fuelLog', () {
    test('maps a valid fuel + water batch and computes cost', () {
      final batch = ImportService.parse('''
        { "sisuMateImport": 1, "kind": "fuelLog", "items": [
          { "type": "Fuel", "date": "2026-07-05", "liters": 40, "pricePerLiter": 2.0 },
          { "type": "Water", "liters": 200 }
        ] }
      ''');
      expect(batch.kind, ImportService.kindFuelLog);
      expect(batch.count, 2);
      expect(batch.fuelLogs[0].type, 'Fuel');
      expect(batch.fuelLogs[0].totalCost, 80.0);
      expect(batch.fuelLogs[1].type, 'Water');
      expect(batch.fuelLogs[1].pricePerLiter, 0);
      expect(batch.fuelLogs[0].supabaseId, isNotEmpty);
    });

    test('all-or-nothing: a bad item throws with its index and a reason', () {
      try {
        ImportService.parse('''
          { "sisuMateImport": 1, "kind": "fuelLog", "items": [
            { "type": "Fuel", "liters": 40 },
            { "type": "Petrol", "liters": 10 }
          ] }
        ''');
        fail('expected ImportException');
      } on ImportException catch (e) {
        expect(e.itemIndex, 1);
        expect(e.display, contains('Item 2'));
        expect(e.message, contains('type'));
      }
    });

    test('ignores unknown/extra fields an AI might add', () {
      // Only the required fields must be present; anything else is ignored, so
      // an LLM adding "station", "attendant", etc. does not break the import.
      final batch = ImportService.parse('''
        { "sisuMateImport": 1, "kind": "fuelLog", "items": [
          { "type": "Fuel", "liters": 40, "pricePerLiter": 2.0,
            "station": "Shell Marina", "attendant": "Jo", "pumpNumber": 3 }
        ] }
      ''');
      expect(batch.count, 1);
      expect(batch.fuelLogs.single.liters, 40);
      expect(batch.fuelLogs.single.totalCost, 80.0);
    });

    test('rejects a missing required number (liters)', () {
      expect(
          () => ImportService.parse(
              '{"sisuMateImport":1,"kind":"fuelLog","items":[{"type":"Fuel"}]}'),
          throwsA(predicate(
              (e) => e is ImportException && e.message.contains('liters'))));
    });

    test('rejects a malformed date', () {
      expect(
          () => ImportService.parse(
              '{"sisuMateImport":1,"kind":"fuelLog","items":[{"liters":1,"date":"last tuesday"}]}'),
          throwsA(predicate(
              (e) => e is ImportException && e.itemIndex == 0)));
    });
  });

  group('ImportService.parse — inventory', () {
    test('maps items and defaults quantity to 1', () {
      final batch = ImportService.parse('''
        { "sisuMateImport": 1, "kind": "inventory", "items": [
          { "name": "Flares", "location": "Grab bag" },
          { "name": "Fenders", "quantity": 4, "unit": "pcs" }
        ] }
      ''');
      expect(batch.count, 2);
      expect(batch.inventoryItems[0].name, 'Flares');
      expect(batch.inventoryItems[0].quantity, 1);
      expect(batch.inventoryItems[1].quantity, 4);
    });

    test('rejects an item with no name', () {
      expect(
          () => ImportService.parse(
              '{"sisuMateImport":1,"kind":"inventory","items":[{"quantity":2}]}'),
          throwsA(predicate(
              (e) => e is ImportException && e.message.contains('name'))));
    });
  });

  group('ImportService.parse — recipe (nested)', () {
    test('maps a recipe and links its ingredients', () {
      final batch = ImportService.parse('''
        { "sisuMateImport": 1, "kind": "recipe", "items": [
          { "name": "Mai Tai", "recipeType": "cocktail",
            "ingredients": [
              { "name": "rum", "quantity": 60, "unit": "ml" },
              { "name": "mint", "isGarnish": true }
            ] }
        ] }
      ''');
      expect(batch.count, 1);
      final r = batch.recipes.single;
      expect(r.recipe.name, 'Mai Tai');
      expect(r.recipe.recipeType, 'cocktail');
      expect(r.ingredients, hasLength(2));
      // ingredients are linked to their parent recipe and ordered
      expect(r.ingredients.every(
          (ing) => ing.recipeSupabaseId == r.recipe.supabaseId), isTrue);
      expect(r.ingredients[0].sortOrder, 0);
      expect(r.ingredients[1].isGarnish, isTrue);
    });

    test('rejects an ingredient with no name', () {
      expect(
          () => ImportService.parse(
              '{"sisuMateImport":1,"kind":"recipe","items":[{"name":"X","ingredients":[{"quantity":1}]}]}'),
          throwsA(isA<ImportException>()));
    });

    test('accepts meal-course recipeType as menu with cuisine tag', () {
      final batch = ImportService.parse(jsonEncode({
        'sisuMateImport': 1,
        'kind': 'recipe',
        'items': [
          {
            'name': 'Side Salad',
            'recipeType': 'side',
            'ingredients': [
              {'name': 'Lettuce', 'quantity': 1},
            ],
          },
        ],
      }));
      expect(batch.recipes.single.recipe.recipeType, 'menu');
      expect(
        batch.recipes.single.recipe.cuisine.map((c) => c.toLowerCase()),
        contains('side'),
      );
    });

    test('rejects an unknown recipeType', () {
      expect(
          () => ImportService.parse(
              '{"sisuMateImport":1,"kind":"recipe","items":[{"name":"X","recipeType":"soup"}]}'),
          throwsA(predicate((e) =>
              e is ImportException && e.message.contains('recipeType'))));
    });
  });

  group('ImportService.parse — crew / document / maintenance', () {
    test('crew maps required name and defaults role', () {
      final batch = ImportService.parse(
          '{"sisuMateImport":1,"kind":"crew","items":[{"name":"Ada"},{"name":"Bo","role":"Cook"}]}');
      expect(batch.kind, ImportService.kindCrew);
      expect(batch.count, 2);
      expect(batch.crewMembers[0].name, 'Ada');
      expect(batch.crewMembers[0].role, 'Crew');
      expect(batch.crewMembers[1].role, 'Cook');
    });

    test('crew rejects a missing name', () {
      expect(
          () => ImportService.parse(
              '{"sisuMateImport":1,"kind":"crew","items":[{"role":"Cook"}]}'),
          throwsA(isA<ImportException>()));
    });

    test('document maps title + expiry and defaults type', () {
      final batch = ImportService.parse(
          '{"sisuMateImport":1,"kind":"document","items":[{"title":"Reg","expiry":"2027-06-01"}]}');
      expect(batch.documents.single.title, 'Reg');
      expect(batch.documents.single.type, 'Other');
      expect(batch.documents.single.expiry, DateTime(2027, 6, 1));
    });

    test('maintenance maps description + interval fields', () {
      final batch = ImportService.parse(
          '{"sisuMateImport":1,"kind":"maintenance","items":[{"description":"Oil change","intervalHours":250}]}');
      expect(batch.maintenanceTasks.single.description, 'Oil change');
      expect(batch.maintenanceTasks.single.intervalHours, 250);
    });

    test('maintenance rejects a missing description', () {
      expect(
          () => ImportService.parse(
              '{"sisuMateImport":1,"kind":"maintenance","items":[{"intervalHours":10}]}'),
          throwsA(isA<ImportException>()));
    });

    test('checklist maps title (defaulting name) with empty group', () {
      final batch = ImportService.parse(
          '{"sisuMateImport":1,"kind":"checklist","items":[{"title":"Check bilge"}]}');
      expect(batch.kind, ImportService.kindChecklist);
      expect(batch.checklistItems.single.title, 'Check bilge');
      expect(batch.checklistItems.single.name, 'Check bilge');
      // group is assigned by the importing screen (option A), not the file
      expect(batch.checklistItems.single.groupSupabaseId, '');
    });

    test('checklist rejects a missing title', () {
      expect(
          () => ImportService.parse(
              '{"sisuMateImport":1,"kind":"checklist","items":[{"notes":"x"}]}'),
          throwsA(isA<ImportException>()));
    });

    test('shopping maps name + category + defaults quantity to 1', () {
      final batch = ImportService.parse('''
        { "sisuMateImport": 1, "kind": "shopping", "items": [
          { "name": "Fenders", "category": "Deck Gear", "quantity": 4 },
          { "name": "Rope" }
        ] }
      ''');
      expect(batch.kind, ImportService.kindShopping);
      expect(batch.count, 2);
      expect(batch.shoppingItems[0].item.name, 'Fenders');
      expect(batch.shoppingItems[0].categoryName, 'Deck Gear');
      // the category name also becomes the item's `origin` (the visible group)
      expect(batch.shoppingItems[0].item.origin, 'Deck Gear');
      expect(batch.shoppingItems[0].item.quantity, 4);
      expect(batch.shoppingItems[1].item.quantity, 1);
      expect(batch.shoppingItems[1].categoryName, isNull);
      expect(batch.shoppingItems[1].item.origin, 'spares');
    });

    test('shopping rejects a missing name', () {
      expect(
          () => ImportService.parse(
              '{"sisuMateImport":1,"kind":"shopping","items":[{"category":"X"}]}'),
          throwsA(isA<ImportException>()));
    });
  });

  group('ImportService — export / sample round-trips through parse', () {
    test('every kind\'s sample template re-parses cleanly', () {
      for (final kind in ImportService.supportedKinds) {
        final batch = ImportService.parse(ImportService.sampleFor(kind));
        expect(batch.kind, kind);
        expect(batch.count, greaterThan(0));
      }
    });

    test('exported fuel logs re-import to equivalent values', () {
      final original = ImportService.parse(
          ImportService.sampleFor(ImportService.kindFuelLog));
      final json = ImportService.exportFuelLogs(original.fuelLogs);
      final round = ImportService.parse(json);
      expect(round.fuelLogs.map((e) => e.liters),
          original.fuelLogs.map((e) => e.liters));
      expect(round.fuelLogs.map((e) => e.totalCost),
          original.fuelLogs.map((e) => e.totalCost));
    });

    test('exported recipes preserve ingredient linkage on re-import', () {
      final original =
          ImportService.parse(ImportService.sampleFor(ImportService.kindRecipe));
      final json = ImportService.exportRecipes(original.recipes);
      final round = ImportService.parse(json);
      final r = round.recipes.single;
      expect(r.ingredients, isNotEmpty);
      expect(
          r.ingredients.every((i) => i.recipeSupabaseId == r.recipe.supabaseId),
          isTrue);
    });

    test('recipe sample includes description, glassware, and story', () {
      final batch =
          ImportService.parse(ImportService.sampleFor(ImportService.kindRecipe));
      final recipe = batch.recipes.single.recipe;
      expect(recipe.description, isNotNull);
      expect(recipe.description, isNotEmpty);
      expect(recipe.glassware, isNotNull);
      expect(recipe.glassware, isNotEmpty);
      expect(recipe.story, isNotNull);
      expect(recipe.story, isNotEmpty);
    });

    test('exported recipes round-trip description, glassware, and story', () {
      final original =
          ImportService.parse(ImportService.sampleFor(ImportService.kindRecipe));
      final src = original.recipes.single.recipe;
      final json = ImportService.exportRecipes(original.recipes);
      final round = ImportService.parse(json);
      final dst = round.recipes.single.recipe;
      expect(dst.description, src.description);
      expect(dst.glassware, src.glassware);
      expect(dst.story, src.story);
    });

    test('recipe import accepts glasstype as alias for glassware', () {
      final batch = ImportService.parse('''
        { "sisuMateImport": 1, "kind": "recipe", "items": [
          {
            "name": "Old Fashioned",
            "recipeType": "cocktail",
            "description": "Whiskey, sugar, bitters",
            "glasstype": "Rocks glass",
            "story": "A classic of the American bar.",
            "ingredients": [
              { "name": "bourbon", "quantity": 60, "unit": "ml" }
            ]
          }
        ] }
      ''');
      final recipe = batch.recipes.single.recipe;
      expect(recipe.glassware, 'Rocks glass');
      expect(recipe.description, 'Whiskey, sugar, bitters');
      expect(recipe.story, 'A classic of the American bar.');
    });

    test('recipe import maps cuisine and flavorProfiles as lists', () {
      final batch = ImportService.parse('''
        { "sisuMateImport": 1, "kind": "recipe", "items": [
          {
            "name": "Port Au Prince",
            "recipeType": "cocktail",
            "cuisine": ["Tiki", "Classic", "tiki"],
            "flavorProfiles": ["rum-forward", "citrus", "spicy", "tropical"],
            "description": "A vibrant Haitian-inspired rum punch.",
            "story": "Martin Cate's take.",
            "glasstype": "Rocks Glass",
            "prepMinutes": 5,
            "ingredients": [
              {
                "name": "Dark Jamaican Rum",
                "quantity": 2.0,
                "unit": "oz",
                "flavorProfiles": ["bold", "rum-forward"]
              }
            ]
          }
        ] }
      ''');
      final recipe = batch.recipes.single.recipe;
      // Case-insensitive dedupe keeps first casing of "Tiki".
      expect(recipe.cuisine, ['Tiki', 'Classic']);
      // Recipe flavors + rolled-up ingredient flavors (deduped).
      expect(
          recipe.flavorProfiles,
          containsAll(
              ['rum-forward', 'citrus', 'spicy', 'tropical', 'bold']));
      expect(recipe.glassware, 'Rocks Glass');
      expect(recipe.prepMinutes, 5);
      expect(batch.recipes.single.ingredients.single.name, 'Dark Jamaican Rum');
    });

    test('recipe import rolls ingredient flavorProfiles onto the cocktail', () {
      final batch = ImportService.parse('''
        { "sisuMateImport": 1, "kind": "recipe", "items": [
          {
            "name": "Spicy Rum Sour",
            "recipeType": "cocktail",
            "flavorProfiles": ["citrus"],
            "ingredients": [
              {
                "name": "Dark Rum",
                "quantity": 60,
                "unit": "ml",
                "flavorProfiles": ["rum-forward", "spicy", "citrus"]
              },
              {
                "name": "Lime",
                "quantity": 30,
                "unit": "ml",
                "flavorProfiles": ["citrus", "tart"]
              }
            ]
          }
        ] }
      ''');
      final recipe = batch.recipes.single.recipe;
      expect(recipe.flavorProfiles,
          ['citrus', 'rum-forward', 'spicy', 'tart']);
    });

    test('recipe import accepts cuisine as a single string', () {
      final batch = ImportService.parse('''
        { "sisuMateImport": 1, "kind": "recipe", "items": [
          {
            "name": "Simple",
            "recipeType": "menu",
            "cuisine": "Italian",
            "ingredients": [{ "name": "pasta" }]
          }
        ] }
      ''');
      expect(batch.recipes.single.recipe.cuisine, ['Italian']);
    });

    test('exported recipes round-trip cuisine and flavorProfiles lists', () {
      final original =
          ImportService.parse(ImportService.sampleFor(ImportService.kindRecipe));
      final src = original.recipes.single.recipe;
      final json = ImportService.exportRecipes(original.recipes);
      final dst = ImportService.parse(json).recipes.single.recipe;
      expect(dst.cuisine, src.cuisine);
      expect(dst.flavorProfiles, src.flavorProfiles);
    });
  });

  group('ImportService IMP2 — upsert / dedupe helpers', () {
    test('honours supabaseId from file for inventory', () {
      final batch = ImportService.parse('''
        { "sisuMateImport": 1, "kind": "inventory", "items": [
          { "supabaseId": "stable-inv-1", "name": "Anchor", "quantity": 1 }
        ] }
      ''');
      expect(batch.inventoryItems.single.supabaseId, 'stable-inv-1');
    });

    test('export → re-parse keeps crew supabaseId', () {
      final member = CrewMember()
        ..supabaseId = 'crew-abc'
        ..name = 'Alex'
        ..role = 'Captain';
      final json = ImportService.exportCrew([member]);
      final batch = ImportService.parse(json);
      expect(batch.crewMembers.single.supabaseId, 'crew-abc');
      expect(batch.crewMembers.single.name, 'Alex');
    });

    test('matchExisting prefers id then content key', () {
      final a = CrewMember()
        ..supabaseId = 'id-1'
        ..name = 'Pat';
      final b = CrewMember()
        ..supabaseId = 'id-2'
        ..name = 'Sam';
      final byId = ImportService.matchExisting(
        existing: [a, b],
        incomingId: 'id-2',
        idOf: (e) => e.supabaseId,
        contentKeyOf: ImportService.contentKeyCrew,
        incomingContentKey: 'nobody',
      );
      expect(byId?.supabaseId, 'id-2');

      final byName = ImportService.matchExisting(
        existing: [a, b],
        incomingId: 'brand-new',
        idOf: (e) => e.supabaseId,
        contentKeyOf: ImportService.contentKeyCrew,
        incomingContentKey: ImportService.contentKeyCrew(a),
      );
      expect(byName?.supabaseId, 'id-1');
    });

    test('fuel always mints new ids even if supabaseId present', () {
      final batch = ImportService.parse('''
        { "sisuMateImport": 1, "kind": "fuelLog", "items": [
          { "supabaseId": "fuel-x", "type": "Fuel", "liters": 10 }
        ] }
      ''');
      // Fuel fill-ups must not dedupe — id is always minted.
      expect(batch.fuelLogs.single.supabaseId, isNot('fuel-x'));
      expect(batch.fuelLogs.single.supabaseId, startsWith('imp_fuel_'));
    });
  });

  group('ImportService.parse — SYN3 active boat id', () {
    test('defaults to zero-UUID placeholder without boatSupabaseId', () {
      final batch = ImportService.parse('''
        { "sisuMateImport": 1, "kind": "crew", "items": [
          { "name": "Alex" }
        ] }
      ''');
      expect(batch.crewMembers.single.boatSupabaseId,
          '00000000-0000-0000-0000-000000000000');
    });

    test('stamps boatSupabaseId on all boat-scoped kinds', () {
      const boat = 'boat-active-123';
      final crew = ImportService.parse(
        '''{ "sisuMateImport": 1, "kind": "crew", "items": [
          { "name": "Alex" }
        ] }''',
        boatSupabaseId: boat,
      );
      expect(crew.crewMembers.single.boatSupabaseId, boat);

      final inv = ImportService.parse(
        '''{ "sisuMateImport": 1, "kind": "inventory", "items": [
          { "name": "Fender" }
        ] }''',
        boatSupabaseId: boat,
      );
      expect(inv.inventoryItems.single.boatSupabaseId, boat);

      final fuel = ImportService.parse(
        '''{ "sisuMateImport": 1, "kind": "fuelLog", "items": [
          { "type": "Fuel", "liters": 10 }
        ] }''',
        boatSupabaseId: boat,
      );
      expect(fuel.fuelLogs.single.boatSupabaseId, boat);

      final recipe = ImportService.parse(
        '''{ "sisuMateImport": 1, "kind": "recipe", "items": [
          { "name": "Pasta", "recipeType": "menu" }
        ] }''',
        boatSupabaseId: boat,
      );
      expect(recipe.recipes.single.recipe.boatSupabaseId, boat);
    });

    test('applyBoatId mutates an already-parsed batch', () {
      final batch = ImportService.parse('''
        { "sisuMateImport": 1, "kind": "document", "items": [
          { "title": "Registration" }
        ] }
      ''');
      batch.applyBoatId('boat-xyz');
      expect(batch.documents.single.boatSupabaseId, 'boat-xyz');
    });
  });
}
