import 'dart:convert';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sisu_mate/core/di.dart';
import 'package:sisu_mate/data/drift/app_database.dart';
import 'package:sisu_mate/services/revenuecat_service.dart';
import 'package:sisu_mate/ui/chef/chef_screen.dart';

import 'test_helpers/platform_mocks.dart';

/// #225: a fully-tagged Chef recipe card (cuisine + flavor + cooking-method
/// chips, ingredient count, prep/cook time, an allergen line, AND a dietary
/// badge row all present at once — as "Blackened Red Snapper" was in the
/// on-device error log this was auto-filed from) stacked 6 optional
/// sections into a fixed-height grid cell and overflowed by 20px.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late AppDatabase db;

  setUp(() {
    mockConnectivityChannel();
    mockPathProviderChannel();
    mockSharedPreferencesChannel();
    db = AppDatabase.forTesting(NativeDatabase.memory());
    RevenueCatService.debugProOverrideForTests = false;
  });

  tearDown(() async {
    RevenueCatService.debugProOverrideForTests = null;
    await db.close();
  });

  testWidgets(
      'a recipe card with every optional section populated at once does '
      'not overflow its grid cell', (tester) async {
    // Narrow phone-width viewport — the on-device overflow report showed a
    // 144px-wide grid cell (2-column grid, 16px padding/spacing), which
    // only reproduces on a narrow-ish surface; the default 800x600 test
    // surface gives each cell much more room and never overflows.
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    tester.view.physicalSize = const Size(340, 800);
    tester.view.devicePixelRatio = 1.0;

    await db.into(db.recipes).insert(RecipesCompanion.insert(
          supabaseId: const Value('recipe_maxed'),
          name: const Value('Blackened Red Snapper'),
          recipeType: const Value('menu'),
          cuisine: Value(jsonEncode(['Main', 'New York'])),
          flavorProfiles: Value(jsonEncode(['mild', 'sweet'])),
          cookingMethod: const Value('Stovetop'),
          prepMinutes: const Value(10),
          cookMinutes: const Value(10),
        ));
    await db.into(db.recipeIngredients).insert(
          RecipeIngredientsCompanion.insert(
            supabaseId: const Value('ri_maxed'),
            recipeSupabaseId: const Value('recipe_maxed'),
            name: const Value('Butter'),
          ),
        );
    await db.into(db.pantryIngredients).insert(
          PantryIngredientsCompanion.insert(
            supabaseId: const Value('pantry_butter'),
            name: const Value('Butter'),
            inMyPantry: const Value(true),
            allergenTags: Value(jsonEncode(['dairy'])),
            dietaryTags: Value(jsonEncode(['gluten-free'])),
          ),
        );

    final container = ProviderContainer(overrides: [
      appDatabaseProvider.overrideWithValue(db),
      isProProvider.overrideWith((ref) => Stream.value(true)),
    ]);
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: ChefScreen()),
      ),
    );
    await tester.pump();
    await tester.pump();
    await tester.pump();

    // The debug overflow indicator is painted directly (not a widget), so
    // the framework-level assertion flutter_test captures via
    // takeException() is the actual signal — matches the "A RenderFlex
    // overflowed by 20 pixels" FlutterError the on-device log captured.
    expect(tester.takeException(), isNull);

    // Content is still all there — scrollable, not silently dropped.
    expect(find.text('Blackened Red Snapper'), findsOneWidget);
    expect(find.text('4 ingredients'), findsNothing); // sanity: not garbage
    expect(find.text('1 ingredients'), findsOneWidget);
    expect(find.text('dairy'), findsOneWidget);
    expect(find.text('gluten-free'), findsOneWidget);
  });
}
