import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sisu_mate/data/drift/app_database.dart';
import 'package:sisu_mate/data/repositories/bar_ingredient_repository_impl.dart';
import 'package:sisu_mate/models/models.dart';

// Bar ingredients (My Bar) on Drift (S1). Sync-participating (SYN2).
void main() {
  late AppDatabase db;
  late BarIngredientRepositoryImpl repo;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = BarIngredientRepositoryImpl(db);
  });

  tearDown(() async => db.close());

  group('BarIngredientRepositoryImpl CRUD', () {
    // SHARE4: unscoped user writes are stamped with the active boat GUID.
    test('add stamps active boat GUID when boatSupabaseId is empty', () async {
      await db.into(db.userSettingsTable).insert(
            UserSettingsTableCompanion.insert(
              id: const Value(1),
              activeBoatSupabaseId: const Value('boat_guid_1'),
            ),
          );
      await repo.addBarIngredient(BarIngredient()
        ..supabaseId = 'bar_new'
        ..name = 'Aquavit');

      final all = await repo.watchBarIngredients().first;
      expect(all.single.boatSupabaseId, 'boat_guid_1');
    });

    test('Create: addBarIngredient persists a new ingredient', () async {
      await repo.addBarIngredient(BarIngredient()
        ..supabaseId = 'bar_1'
        ..name = 'White Rum'
        ..category = 'spirit'
        ..boatSupabaseId = 'boat_1'); // SHARE4 per-boat scope

      final all = await repo.watchBarIngredients().first;
      expect(all, hasLength(1));
      expect(all.single.name, 'White Rum');
      expect(all.single.boatSupabaseId, 'boat_1');
    });

    test('Read: watchBarIngredients is alphabetical by name (stable)',
        () async {
      await repo.addBarIngredient(BarIngredient()
        ..supabaseId = 'bar_a'
        ..name = 'Amaro'
        ..inMyBar = false);
      await repo.addBarIngredient(BarIngredient()
        ..supabaseId = 'bar_z'
        ..name = 'Zinfandel'
        ..inMyBar = true);

      // Stock-first ordering is UI-only so toggling does not jump the list.
      final ingredients = await repo.watchBarIngredients().first;
      expect(ingredients.map((i) => i.name), ['Amaro', 'Zinfandel']);
    });

    test('Update: toggleInMyBar flips inMyBar and persists it', () async {
      final ingredient = BarIngredient()
        ..supabaseId = 'bar_1'
        ..name = 'White Rum';
      await repo.addBarIngredient(ingredient);
      expect(ingredient.inMyBar, isFalse);

      await repo.toggleInMyBar(ingredient);

      final all = await repo.watchBarIngredients().first;
      expect(all.single.inMyBar, isTrue);
    });

    test('purchaseHistory round-trips through the JSON column', () async {
      final ingredient = BarIngredient()
        ..supabaseId = 'bar_1'
        ..name = 'White Rum';
      await repo.addBarIngredient(ingredient);

      await repo.recordPurchase(ingredient,
          price: 24.50, place: 'Marina Liquor', priceUnit: '750ml');

      final saved = (await repo.watchBarIngredients().first).single;
      expect(saved.lastKnownPrice, 24.50);
      expect(saved.purchaseHistory, hasLength(1));
      expect(saved.purchaseHistory.single.place, 'Marina Liquor');
    });

    test('Delete: deleteBarIngredient removes it from the database', () async {
      final ingredient = BarIngredient()
        ..supabaseId = 'bar_1'
        ..name = 'To remove';
      await repo.addBarIngredient(ingredient);

      await repo.deleteBarIngredient(ingredient);

      final all = await repo.watchBarIngredients().first;
      expect(all, isEmpty);
    });
  });
}
