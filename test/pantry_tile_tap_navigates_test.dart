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
import 'package:sisu_mate/ui/chef/chef_screen.dart';
import 'package:sisu_mate/ui/cocktails/cocktails_screen.dart';

import 'test_helpers/fake_auth_backend.dart';
import 'test_helpers/platform_mocks.dart';

/// #340: tapping a My Pantry (and My Bar) card must navigate to ingredient
/// detail — not leave focus on the search field.
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
    RevenueCatService.debugProOverrideForTests = true;
  });

  tearDown(() async {
    RevenueCatService.debugProOverrideForTests = null;
    authBackend.dispose();
    await db.close();
  });

  Future<void> pumpChef(WidgetTester tester) async {
    final container = ProviderContainer(overrides: [
      appDatabaseProvider.overrideWithValue(db),
      isProProvider.overrideWith((ref) => Stream.value(true)),
      authServiceProvider
          .overrideWith((ref) => AuthService(ref, backend: authBackend)),
    ]);
    addTearDown(container.dispose);

    final router = GoRouter(
      initialLocation: AppRoutes.chef,
      routes: [
        GoRoute(
          path: AppRoutes.chef,
          builder: (context, state) => const ChefScreen(),
        ),
        GoRoute(
          path: AppRoutes.pantryIngredientDetail,
          builder: (context, state) =>
              const Scaffold(body: Text('pantry detail stub')),
        ),
      ],
    );

    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(routerConfig: router),
    ));
    await tester.pump();
    await tester.pump();
  }

  Future<void> pumpCocktails(WidgetTester tester) async {
    final container = ProviderContainer(overrides: [
      appDatabaseProvider.overrideWithValue(db),
      isProProvider.overrideWith((ref) => Stream.value(true)),
      authServiceProvider
          .overrideWith((ref) => AuthService(ref, backend: authBackend)),
    ]);
    addTearDown(container.dispose);

    final router = GoRouter(
      initialLocation: AppRoutes.cocktails,
      routes: [
        GoRoute(
          path: AppRoutes.cocktails,
          builder: (context, state) => const CocktailsScreen(),
        ),
        GoRoute(
          path: AppRoutes.barIngredientDetail,
          builder: (context, state) =>
              const Scaffold(body: Text('bar detail stub')),
        ),
      ],
    );

    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(routerConfig: router),
    ));
    await tester.pump();
    await tester.pump();
  }

  testWidgets('My Pantry card tap opens ingredient detail', (tester) async {
    await db.into(db.pantryIngredients).insert(
          PantryIngredientsCompanion.insert(
            supabaseId: const Value('pantry_balsamic'),
            name: const Value('Aged Balsamic Vinegar'),
            inMyPantry: const Value(true),
          ),
        );
    await pumpChef(tester);
    await tester.tap(find.text('My Pantry'));
    await tester.pumpAndSettle();

    expect(find.text('Search pantry...'), findsOneWidget);
    await tester.tap(find.text('Aged Balsamic Vinegar'));
    await tester.pumpAndSettle();

    expect(find.text('pantry detail stub'), findsOneWidget);
    expect(find.byType(TextField), findsNothing,
        reason: 'must leave the pantry list (search field) after tap');
  });

  testWidgets('My Bar card tap opens ingredient detail', (tester) async {
    await db.into(db.barIngredients).insert(
          BarIngredientsCompanion.insert(
            supabaseId: const Value('bar_gin'),
            name: const Value('London Dry Gin'),
            inMyBar: const Value(true),
          ),
        );
    await pumpCocktails(tester);
    await tester.tap(find.text('My Bar'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('London Dry Gin'));
    await tester.pumpAndSettle();

    expect(find.text('bar detail stub'), findsOneWidget);
  });
}
