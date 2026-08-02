import 'dart:convert';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sisu_mate/core/di.dart';
import 'package:sisu_mate/data/drift/app_database.dart';
import 'package:sisu_mate/data/seed/bundled_data_seeder.dart';
import 'package:sisu_mate/services/auth_service.dart';
import 'package:sisu_mate/services/revenuecat_service.dart';
import 'package:sisu_mate/ui/cocktails/cocktails_screen.dart';

import 'test_helpers/fake_auth_backend.dart';
import 'test_helpers/platform_mocks.dart';

/// #135: House tab tiles didn't render `Recipe.flavorProfiles` at all, and
/// the seeded syrups never set the field in the first place, so cocktail/
/// ingredient-tile parity was missing on two fronts.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late AppDatabase db;
  late FakeAuthBackend authBackend;

  setUp(() {
    mockConnectivityChannel();
    mockPathProviderChannel();
    mockSharedPreferencesChannel();
    db = AppDatabase.forTesting(NativeDatabase.memory());
    authBackend = FakeAuthBackend();
    RevenueCatService.debugProOverrideForTests = false;
  });

  tearDown(() async {
    RevenueCatService.debugProOverrideForTests = null;
    authBackend.dispose();
    await db.close();
  });

  testWidgets('House tab tile shows flavor tag chips when the recipe has them',
      (tester) async {
    await db.into(db.recipes).insert(RecipesCompanion.insert(
          supabaseId: const Value('syrup_test'),
          name: const Value('Test Syrup'),
          recipeType: const Value('syrup'),
          flavorProfiles: Value(jsonEncode(['nutty', 'sweet', 'floral'])),
        ));

    final container = ProviderContainer(overrides: [
      appDatabaseProvider.overrideWithValue(db),
      isProProvider.overrideWith((ref) => Stream.value(true)),
      authServiceProvider
          .overrideWith((ref) => AuthService(ref, backend: authBackend)),
    ]);
    addTearDown(container.dispose);
    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(home: CocktailsScreen()),
    ));
    await tester.pump();
    await tester.pump();

    await tester.tap(find.text('House'));
    await tester.pumpAndSettle();

    expect(find.text('nutty'), findsOneWidget);
    expect(find.text('sweet'), findsOneWidget);
  });

  testWidgets('House tab tile shows nothing extra when flavorProfiles is empty',
      (tester) async {
    await db.into(db.recipes).insert(RecipesCompanion.insert(
          supabaseId: const Value('syrup_bare'),
          name: const Value('Bare Syrup'),
          recipeType: const Value('syrup'),
        ));

    final container = ProviderContainer(overrides: [
      appDatabaseProvider.overrideWithValue(db),
      isProProvider.overrideWith((ref) => Stream.value(true)),
      authServiceProvider
          .overrideWith((ref) => AuthService(ref, backend: authBackend)),
    ]);
    addTearDown(container.dispose);
    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(home: CocktailsScreen()),
    ));
    await tester.pump();
    await tester.pump();

    await tester.tap(find.text('House'));
    await tester.pumpAndSettle();

    expect(find.text('Bare Syrup'), findsOneWidget);
  });

  test('every seeded syrup/house mix has 2-4 flavor tags', () async {
    AppDatabase.setInstanceForTesting(db);
    await seedBundledData();

    final syrups = await (db.select(db.recipes)
          ..where((t) => t.recipeType.equals('syrup')))
        .get();
    expect(syrups, isNotEmpty);

    for (final syrup in syrups) {
      final tags = (jsonDecode(syrup.flavorProfiles) as List).cast<String>();
      expect(tags.length, inInclusiveRange(2, 4),
          reason: '"${syrup.name}" has ${tags.length} flavor tags '
              '(${tags.join(', ')}) — expected 2-4 (#135)');
    }
  });
}
