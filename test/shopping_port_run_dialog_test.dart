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
import 'package:sisu_mate/ui/settings/llm_api_key_dialog.dart';
import 'package:sisu_mate/ui/settings/settings_screen.dart';
import 'package:sisu_mate/ui/shopping/shopping_port_run_dialog.dart';
import 'package:sisu_mate/ui/shopping/shopping_screen.dart';

import 'test_helpers/fake_auth_backend.dart';
import 'test_helpers/platform_mocks.dart';

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

  Future<void> seed({String? llmApiKey, String? llmApiKeyProvider}) async {
    await db.into(db.boats).insert(BoatsCompanion.insert(
          supabaseId: const Value('boat_1'),
          name: const Value('Sisu'),
          llmApiKeys: Value(llmApiKey == null || llmApiKeyProvider == null
              ? '[]'
              : '[{"provider":"$llmApiKeyProvider","apiKey":"$llmApiKey","shared":false}]'),
          activeLlmProvider: Value(llmApiKeyProvider),
        ));
    await db.into(db.userSettingsTable).insert(
          UserSettingsTableCompanion.insert(
            id: const Value(1),
            activeBoatSupabaseId: const Value('boat_1'),
          ),
        );
    await db.into(db.shoppingCategories).insert(
          ShoppingCategoriesCompanion.insert(
            supabaseId: const Value('cat_pantry'),
            name: const Value('Pantry'),
          ),
        );
    await db.into(db.shoppingItems).insert(
          ShoppingItemsCompanion.insert(
            supabaseId: const Value('item_beef'),
            categorySupabaseId: const Value('cat_pantry'),
            name: const Value('Beef Tenderloin'),
            origin: const Value('pantry'),
            lastPurchasePrice: const Value(6),
          ),
        );
    await db.into(db.shoppingItems).insert(
          ShoppingItemsCompanion.insert(
            supabaseId: const Value('item_rum'),
            categorySupabaseId: const Value('cat_pantry'),
            name: const Value('Rum'),
            origin: const Value('bar'),
            lastPurchasePrice: const Value(20),
          ),
        );
  }

  ProviderContainer container() {
    final c = ProviderContainer(overrides: [
      appDatabaseProvider.overrideWithValue(db),
      isProProvider.overrideWith((ref) => Stream.value(true)),
      authServiceProvider
          .overrideWith((ref) => AuthService(ref, backend: authBackend)),
    ]);
    addTearDown(c.dispose);
    return c;
  }

  testWidgets('#337 title-bar Plan port run opens offline grouped sheet',
      (tester) async {
    await seed();
    await tester.pumpWidget(UncontrolledProviderScope(
      container: container(),
      child: const MaterialApp(home: ShoppingScreen()),
    ));
    await tester.pump();
    await tester.pump();
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Plan port run'));
    await tester.pumpAndSettle();

    expect(find.byType(ShoppingPortRunDialog), findsOneWidget);
    expect(find.textContaining('Port run'), findsOneWidget);
    expect(find.text('Supermarket / market'), findsOneWidget);
    expect(find.textContaining('Beef Tenderloin'), findsWidgets);
    expect(find.text('Liquor / duty-free'), findsOneWidget);
    expect(find.textContaining('Rum'), findsWidgets);
    expect(find.text('Name the shops (live)'), findsOneWidget);
    expect(find.text('Find nearest shop (online)'), findsNothing);
  });

  testWidgets('#337 no key: Name the shops opens AI API Keys', (tester) async {
    await seed();
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (_, _) => const ShoppingScreen(),
        ),
        GoRoute(
          path: AppRoutes.settings,
          builder: (context, state) => SettingsScreen(
            openAiKeys: state.uri.queryParameters['openAiKeys'] == '1',
          ),
        ),
      ],
    );
    await tester.pumpWidget(UncontrolledProviderScope(
      container: container(),
      child: MaterialApp.router(routerConfig: router),
    ));
    await tester.pump();
    await tester.pump();
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Plan port run'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Name the shops (live)'));
    await tester.tap(find.text('Name the shops (live)'));
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.byType(SettingsScreen), findsOneWidget);
    expect(find.byType(LlmApiKeyDialog), findsOneWidget);
    expect(find.text('AI API Keys'), findsWidgets);
    expect(find.text('None set — bring your own to use AI features'),
        findsOneWidget);
  });
}
