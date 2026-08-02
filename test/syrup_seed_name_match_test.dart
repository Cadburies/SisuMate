import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sisu_mate/data/drift/app_database.dart';
import 'package:sisu_mate/data/seed/bundled_data_seeder.dart';

/// #134: seeded house-mix `Recipe.name` values must exactly match how
/// cocktails reference them as ingredients, or #133's "used in cocktails"
/// feature silently shows nothing even where a real relationship exists.
/// Regression for the "House Orgeat"/"Orgeat", "House Velvet Falernum"/
/// "Velvet Falernum", "House Grenadine"/"Grenadine", "Demerara Syrup 2:1"/
/// "Demerara Syrup" mismatches found auditing `seed_recipes.dart` against
/// `assets/seed/cocktails_import_seed.json`.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    AppDatabase.setInstanceForTesting(db);
    await seedBundledData();
  });

  tearDown(() async {
    await db.close();
  });

  Future<Set<String>> cocktailNamesUsingIngredient(String ingredientName) async {
    final lower = ingredientName.toLowerCase().trim();
    final ingredientRows = await (db.select(db.recipeIngredients)).get();
    final recipeIds = ingredientRows
        .where((i) => i.name.toLowerCase().trim() == lower)
        .map((i) => i.recipeSupabaseId)
        .toSet();
    if (recipeIds.isEmpty) return {};
    final recipeRows = await (db.select(db.recipes)).get();
    return recipeRows
        .where((r) => recipeIds.contains(r.supabaseId) && r.recipeType == 'cocktail')
        .map((r) => r.name)
        .toSet();
  }

  Future<void> expectSyrupNameMatched(String syrupName) async {
    final syrup = await (db.select(db.recipes)
          ..where((t) => t.name.equals(syrupName))
          ..where((t) => t.recipeType.equals('syrup')))
        .getSingleOrNull();
    expect(syrup, isNotNull, reason: 'seeded syrup "$syrupName" should exist');

    final cocktails = await cocktailNamesUsingIngredient(syrupName);
    expect(cocktails, isNotEmpty,
        reason: 'no seeded cocktail ingredient exactly matches syrup name '
            '"$syrupName" — #133\'s "used in cocktails" would show empty '
            'even though a real relationship exists');
  }

  test('Orgeat matches at least one seeded cocktail ingredient', () async {
    await expectSyrupNameMatched('Orgeat');
  });

  test('Velvet Falernum matches at least one seeded cocktail ingredient',
      () async {
    await expectSyrupNameMatched('Velvet Falernum');
  });

  test('Grenadine matches at least one seeded cocktail ingredient', () async {
    await expectSyrupNameMatched('Grenadine');
  });

  test('Demerara Syrup matches at least one seeded cocktail ingredient',
      () async {
    await expectSyrupNameMatched('Demerara Syrup');
  });

  test('Cinnamon Syrup and Honey Syrup already matched (no rename needed)',
      () async {
    await expectSyrupNameMatched('Cinnamon Syrup');
    await expectSyrupNameMatched('Honey Syrup');
  });
}
