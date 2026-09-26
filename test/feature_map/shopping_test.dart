import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:sisu_mate/core/app_router.dart';
import 'package:sisu_mate/core/di.dart';
import 'package:sisu_mate/core/theme.dart';
import 'package:sisu_mate/data/drift/app_database.dart';
import 'package:sisu_mate/providers/passage_readiness_provider.dart';
import 'package:sisu_mate/services/revenuecat_service.dart';
import 'package:sisu_mate/services/suggestion_engine.dart';
import 'package:sisu_mate/ui/home/home_screen.dart';
import 'package:sisu_mate/ui/shopping/shopping_screen.dart';

import '../test_helpers/platform_mocks.dart';

/// Feature Map scripts for `.ai_context/feature_map/home/shopping/`.
/// Each test name is the feature file's path id, so one feature runs with
/// `--plain-name "<id>"`. Reaches the feature by tapping from Home, not by
/// deep link.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;

  setUp(() {
    mockConnectivityChannel();
    mockPathProviderChannel();
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async {
    RevenueCatService.debugProOverrideForTests = null;
    await db.close();
  });

  // Bounded pumps: Home's banner ad defers its load and the jiggle/ads never
  // settle, so pumpAndSettle would hang.
  Future<void> settle(WidgetTester tester) async {
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 500));
  }

  Future<void> pumpHome(WidgetTester tester, {required bool isPro}) async {
    await tester.binding.setSurfaceSize(const Size(800, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    RevenueCatService.debugProOverrideForTests = isPro;

    final container = ProviderContainer(overrides: [
      appDatabaseProvider.overrideWithValue(db),
      isProProvider.overrideWith((ref) => Stream.value(isPro)),
      boatSuggestionsProvider.overrideWith((ref) => const <BoatSuggestion>[]),
      passageReadinessProvider.overrideWith(
        (ref) => const PassageReadiness(
          status: ReadinessStatus.ready,
          blockers: [],
        ),
      ),
    ]);
    addTearDown(container.dispose);

    final router = GoRouter(
      initialLocation: AppRoutes.home,
      routes: [
        GoRoute(
          path: AppRoutes.home,
          builder: (context, state) => const HomeScreen(),
        ),
        GoRoute(
          path: AppRoutes.shopping,
          builder: (context, state) => const ShoppingScreen(),
        ),
      ],
    );

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(
          theme: sisuMateLightTheme,
          darkTheme: sisuMateDarkTheme,
          themeMode: ThemeMode.dark,
          routerConfig: router,
        ),
      ),
    );
    await settle(tester);
  }

  // Reach: Home → tile "Shopping".
  Future<void> reachShopping(WidgetTester tester) async {
    await tester.tap(find.text('Shopping'));
    await settle(tester);
    expect(find.text('Shopping & Spares'), findsOneWidget);
  }

  testWidgets('home/shopping/add_item', (tester) async {
    await pumpHome(tester, isPro: true);
    await reachShopping(tester);

    await tester.tap(find.byTooltip('Add item'));
    await settle(tester);
    expect(find.text('Add Shopping Item'), findsOneWidget);

    await tester.enterText(
        find.widgetWithText(TextField, 'Item Name'), 'Impeller');
    await tester.tap(find.text('Add Item'));
    await settle(tester);
    expect(find.text('Impeller added to shopping list'), findsOneWidget);
  });

  testWidgets('home/shopping/add_item [free]', (tester) async {
    await pumpHome(tester, isPro: false);
    await reachShopping(tester);

    await tester.tap(find.byTooltip('Add item'));
    await settle(tester);
    expect(find.text('Sisu Mate Pro Required'), findsOneWidget);
    expect(find.text('Add Shopping Item'), findsNothing);
  });
}
