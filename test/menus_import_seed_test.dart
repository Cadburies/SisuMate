import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sisu_mate/data/seed/seed_menus_import.dart';
import 'package:sisu_mate/services/import_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('menus_import_seed.json is valid and complete enough', () async {
    final raw = await rootBundle.loadString(menusImportSeedAsset);
    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    final menus = (decoded['menus'] as List).cast<Map<String, dynamic>>();
    expect(menus.length, greaterThanOrEqualTo(100));

    for (final m in menus) {
      expect(m['supabaseId'], startsWith(menusImportIdPrefix));
      expect(m['recipeType'], 'menu');
      expect((m['name'] as String).isNotEmpty, isTrue);
      expect(m['story'], isNotNull);
      expect((m['story'] as String).toLowerCase(), contains('two'));
      // #214: every seeded meal needs a genuine wine + cocktail pairing.
      expect(m['winePairing'], isNotNull, reason: m['name']);
      expect((m['winePairing'] as String).isNotEmpty, isTrue, reason: m['name']);
      expect(m['cocktailPairing'], isNotNull, reason: m['name']);
      expect((m['cocktailPairing'] as String).isNotEmpty, isTrue,
          reason: m['name']);
      final ings = m['ingredients'] as List? ?? const [];
      expect(ings, isNotEmpty, reason: m['name']);
    }

    // Beef Wellington should list prosciutto / mushroom from instructions.
    final wellington = menus.firstWhere(
      (m) => (m['name'] as String).contains('Wellington'),
    );
    final names = (wellington['ingredients'] as List)
        .map((e) => (e as Map)['name'].toString().toLowerCase())
        .toList();
    expect(names.any((n) => n.contains('prosciutto')), isTrue);
    expect(names.any((n) => n.contains('mushroom') || n.contains('puff')), isTrue);
  });

  test('ImportService accepts meal-course recipeType aliases as menu', () {
    final json = jsonEncode({
      'sisuMateImport': 1,
      'kind': 'recipe',
      'items': [
        {
          'name': 'Test Braai',
          'recipeType': 'braai',
          'cuisine': 'Boer',
          'ingredients': [
            {'name': 'Boerewors', 'quantity': 0.3, 'unit': 'kg'},
          ],
        },
      ],
    });
    final batch = ImportService.parse(json);
    expect(batch.recipes, hasLength(1));
    final r = batch.recipes.single.recipe;
    expect(r.recipeType, 'menu');
    expect(r.cuisine.map((c) => c.toLowerCase()), contains('braai'));
  });
}
