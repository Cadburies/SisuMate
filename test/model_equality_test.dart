import 'package:flutter_test/flutter_test.dart';
import 'package:sisu_mate/models/models.dart';

// Covers S2 (lighter scope, per explicit product decision): value equality
// (==/hashCode) + toString on every domain model, without the full
// freezed/immutability migration S2 originally described. These classes stay
// mutable (Model()..field = x construction is unchanged everywhere), but two
// separately-constructed instances with the same field values now compare
// equal instead of only ever being equal by reference identity — the
// concrete pain point behind T4 ("silent mutation bugs", lib/models/).
//
// Not every one of the 25 models gets its own group here — the pattern is
// identical for all of them (mechanical field-by-field comparison), so this
// file spot-checks representative cases: a plain scalar-only model, a model
// with a List<String> field, a model with a nested List<Model> field (where
// the nested model's own == must also be correct for this to work), and the
// Dart equal-objects-have-equal-hashCodes contract.
void main() {
  group('scalar-only model equality (CrewMember)', () {
    CrewMember build() => CrewMember()
      ..supabaseId = 'crew_1'
      ..boatSupabaseId = 'boat_1'
      ..name = 'Alex'
      ..role = 'First Mate'
      ..lastModified = DateTime.utc(2026, 1, 1);

    test('two separately-built instances with identical fields are equal', () {
      expect(build(), equals(build()));
      expect(build().hashCode, equals(build().hashCode));
    });

    test('differing in one field breaks equality', () {
      final a = build();
      final b = build()..name = 'Jordan';
      expect(a, isNot(equals(b)));
    });

    test('toString is overridden, not the default Instance-of message', () {
      expect(build().toString(), contains('CrewMember('));
      expect(build().toString(), isNot(contains('Instance of')));
    });
  });

  group('List<String> field equality (ChecklistItem.completionHistory)', () {
    ChecklistItem build() => ChecklistItem()
      ..supabaseId = 'item_1'
      ..title = 'Check bilge'
      ..completionHistory = ['2026-01-01T00:00:00.000Z', '2026-01-08T00:00:00.000Z']
      ..lastModified = DateTime.utc(2026, 1, 1)
      ..createdAt = DateTime.utc(2026, 1, 1);

    test('equal when list contents match, even as distinct list instances', () {
      final a = build();
      final b = build();
      expect(identical(a.completionHistory, b.completionHistory), isFalse,
          reason: 'sanity check: these must be distinct List objects, not the same reference');
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('unequal when list contents differ', () {
      final a = build();
      final b = build()..completionHistory = ['2026-01-01T00:00:00.000Z'];
      expect(a, isNot(equals(b)));
    });
  });

  group('nested List<Model> field equality (BarIngredient.purchaseHistory)', () {
    PurchaseRecord record() => PurchaseRecord()
      ..price = 12.5
      ..currency = 'USD'
      ..place = 'Ships Chandlery';

    BarIngredient build() => BarIngredient()
      ..supabaseId = 'bar_1'
      ..name = 'Dark Rum'
      ..purchaseHistory = [record()]
      ..lastModified = DateTime.utc(2026, 1, 1);

    test(
        'equal when nested PurchaseRecord content matches, relying on '
        "PurchaseRecord's own == rather than list reference identity", () {
      expect(build(), equals(build()));
      expect(build().hashCode, equals(build().hashCode));
    });

    test('unequal when a nested record field differs', () {
      final a = build();
      final b = build()..purchaseHistory = [record()..price = 99.0];
      expect(a, isNot(equals(b)));
    });
  });

  group('equal-objects-have-equal-hashCodes contract', () {
    test('holds for a model with multiple list fields (PantryIngredient)', () {
      PantryIngredient build() => PantryIngredient()
        ..supabaseId = 'pantry_1'
        ..name = 'Olive Oil'
        ..flavorProfiles = ['fruity', 'peppery']
        ..allergenTags = []
        ..dietaryTags = ['vegan']
        ..lastModified = DateTime.utc(2026, 1, 1);

      final a = build();
      final b = build();
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode),
          reason: 'Dart contract: a == b must imply a.hashCode == b.hashCode');
    });
  });
}
