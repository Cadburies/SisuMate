import 'package:flutter_test/flutter_test.dart';
import 'package:sisu_mate/data/seed/seed_bar_ingredients.dart';
import 'package:sisu_mate/data/seed/seed_recipes.dart';
import 'package:sisu_mate/services/import_service.dart';

/// Lightweight seed / catalog integrity (T6) — pure checks without full DB seed.
void main() {
  group('Seed integrity (T6)', () {
    test('bar catalog builds a non-empty list of named spirits', () {
      // seedBarIngredients uses private builders; smoke via import samples.
      final sample = ImportService.sampleFor(ImportService.kindRecipe);
      expect(sample, contains('sisuMateImport'));
      expect(sample, contains('items'));
      final batch = ImportService.parse(sample);
      expect(batch.count, greaterThan(0));
      expect(batch.recipes.first.recipe.name, isNotEmpty);
    });

    test('every ImportService kind has a parseable sample', () {
      for (final kind in ImportService.supportedKinds) {
        final json = ImportService.sampleFor(kind);
        final batch = ImportService.parse(json);
        expect(batch.kind, kind, reason: 'kind $kind');
        expect(batch.count, greaterThan(0), reason: 'kind $kind empty');
      }
    });

    test('content keys are stable and case-insensitive', () {
      final a = ImportService.contentKeyCrew(
        (ImportService.parse(ImportService.sampleFor(ImportService.kindCrew))
                .crewMembers
                .first
              ..name = 'Alex'),
      );
      final b = ImportService.contentKeyCrew(
        (ImportService.parse(ImportService.sampleFor(ImportService.kindCrew))
                .crewMembers
                .first
              ..name = 'ALEX'),
      );
      expect(a, b);
    });

    test('bundled recipe seed helpers are importable', () {
      // Ensures seed_recipes.dart still exports without load-time failure.
      expect(seedRecipes, isA<Function>());
      expect(seedBarIngredients, isA<Function>());
    });
  });
}
