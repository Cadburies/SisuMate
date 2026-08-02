import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:sisu_mate/core/app_router.dart';
import 'package:sisu_mate/core/di.dart';
import 'package:sisu_mate/data/drift/app_database.dart';
import 'package:sisu_mate/services/auth_service.dart';
import 'package:sisu_mate/services/revenuecat_service.dart';
import 'package:sisu_mate/ui/cocktails/cocktails_screen.dart';

import 'test_helpers/fake_auth_backend.dart';
import 'test_helpers/platform_mocks.dart';

/// #132: tapping a ranked cocktail under Mixologist -> "Rank my cocktails"
/// must navigate to that cocktail's detail screen — the ListTile had no
/// onTap wired at all.
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

  testWidgets('tapping a ranked cocktail navigates to its detail screen',
      (tester) async {
    await db.into(db.recipes).insert(RecipesCompanion.insert(
          supabaseId: const Value('cocktail_gimlet'),
          name: const Value('Gimlet'),
          recipeType: const Value('cocktail'),
        ));
    await db.into(db.recipeIngredients).insert(RecipeIngredientsCompanion.insert(
          supabaseId: const Value('ri_1'),
          recipeSupabaseId: const Value('cocktail_gimlet'),
          name: const Value('Gin'),
        ));
    await db.into(db.barIngredients).insert(BarIngredientsCompanion.insert(
          supabaseId: const Value('bar_gin'),
          name: const Value('Gin'),
          inMyBar: const Value(true),
        ));

    final container = ProviderContainer(overrides: [
      appDatabaseProvider.overrideWithValue(db),
      isProProvider.overrideWith((ref) => Stream.value(true)),
      authServiceProvider
          .overrideWith((ref) => AuthService(ref, backend: authBackend)),
    ]);
    addTearDown(container.dispose);

    final router = GoRouter(
      initialLocation: AppRoutes.home,
      routes: [
        GoRoute(
          path: AppRoutes.home,
          builder: (context, state) => const CocktailsScreen(),
        ),
        GoRoute(
          path: AppRoutes.cocktailRecipe,
          builder: (context, state) =>
              const Scaffold(body: Text('recipe detail stub')),
        ),
      ],
    );

    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(routerConfig: router),
    ));
    await tester.pump();
    await tester.pump();

    await tester.tap(find.text('Mixologist'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Rank my cocktails'));
    await tester.pumpAndSettle();

    expect(find.text('Gimlet'), findsOneWidget);

    await tester.tap(find.text('Gimlet'));
    await tester.pumpAndSettle();

    expect(find.text('recipe detail stub'), findsOneWidget,
        reason: 'tapping the ranked-list tile must navigate (#132)');
  });
}
