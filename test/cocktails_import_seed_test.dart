import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Validates the processed cocktails import seed asset that ships with the app.
/// (Does not hit Drift — pure file/schema checks.)
void main() {
  final file = File('assets/seed/cocktails_import_seed.json');

  test('cocktails import seed asset exists and is valid JSON', () {
    expect(file.existsSync(), isTrue);
    final decoded = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
    expect(decoded['version'], 1);
    final cocktails = decoded['cocktails'] as List;
    expect(cocktails.length, greaterThan(100));
  });

  test('prose does not embed drink measures (quantities live on ingredients)', () {
    final decoded = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
    final cocktails =
        (decoded['cocktails'] as List).cast<Map<String, dynamic>>();
    final measure = RegExp(r'\d+\s*(?:ml|oz)\b', caseSensitive: false);
    for (final c in cocktails) {
      for (final field in ['instructions', 'description', 'story']) {
        final text = c[field] as String? ?? '';
        expect(measure.hasMatch(text), isFalse,
            reason: '${c['name']} $field still has a measure: $text');
      }
    }
  });

  test('every cocktail is metric, one-glass-friendly, and has a garnish', () {
    final decoded = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
    final cocktails = (decoded['cocktails'] as List).cast<Map<String, dynamic>>();

    const standardMl = {
      5, 10, 15, 20, 25, 30, 40, 45, 50, 60, 75, 90, 100, 120, 150, 180, 200, 240, 300,
    };

    final ids = <String>{};
    for (final c in cocktails) {
      final id = c['supabaseId'] as String;
      expect(id, startsWith('cocktail_imp_'));
      expect(ids.add(id), isTrue, reason: 'duplicate id $id');

      expect(c['name'], isNotEmpty);
      expect((c['description'] as String?)?.length ?? 0, greaterThanOrEqualTo(20));
      expect(c['recipeType'], 'cocktail');
      expect(c['glassware'], isNotEmpty);

      final ings = (c['ingredients'] as List).cast<Map<String, dynamic>>();
      expect(ings, isNotEmpty);
      expect(ings.any((i) => i['isGarnish'] == true), isTrue,
          reason: '${c['name']} missing garnish');

      var liquidMl = 0;
      for (final i in ings) {
        final unit = i['unit'];
        final qty = i['quantity'];
        expect(unit, isNot(equals('oz')), reason: '${c['name']} still has oz');
        if (i['isGarnish'] == true) {
          expect(qty, isNull);
          continue;
        }
        if (unit == 'ml') {
          expect(qty, isA<num>());
          final n = qty as num;
          expect(standardMl.contains(n.round()), isTrue,
              reason: '${c['name']} non-standard ml $qty');
          // no fractional ml
          expect(n == n.roundToDouble(), isTrue);
          liquidMl += n.round();
        }
        if (unit == 'dash') {
          expect(qty, isA<num>());
          expect((qty as num) >= 1, isTrue);
        }
      }
      // Single glass: total liquid should not be a multi-serve bowl.
      expect(liquidMl, lessThanOrEqualTo(220),
          reason: '${c['name']} liquid total ${liquidMl}ml looks multi-serve');
    }
  });
}
