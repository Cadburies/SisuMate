import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sisu_mate/core/di.dart';
import 'package:sisu_mate/core/theme.dart';
import 'package:sisu_mate/data/drift/app_database.dart';
import 'package:sisu_mate/providers/passage_readiness_provider.dart';
import 'package:sisu_mate/services/revenuecat_service.dart';
import 'package:sisu_mate/services/suggestion_engine.dart';
import 'package:sisu_mate/ui/home/home_screen.dart';
import 'package:sisu_mate/ui/shopping/shopping_screen.dart';

import 'test_helpers/platform_mocks.dart';

/// TEST10: cheap performance smoke — first paint settles without hanging, and
/// core module labels are on screen within a bounded number of frames.
///
/// Not a device benchmark; catches infinite rebuild / provider loop regressions.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;

  setUp(() {
    mockConnectivityChannel();
    mockPathProviderChannel();
    db = AppDatabase.forTesting(NativeDatabase.memory());
    RevenueCatService.debugProOverrideForTests = false;
  });

  tearDown(() async {
    RevenueCatService.debugProOverrideForTests = null;
    await db.close();
  });

  ProviderContainer makeContainer() => ProviderContainer(overrides: [
        appDatabaseProvider.overrideWithValue(db),
        isProProvider.overrideWith((ref) => Stream.value(false)),
        boatSuggestionsProvider.overrideWith((ref) => const <BoatSuggestion>[]),
        passageReadinessProvider.overrideWith(
          (ref) => const PassageReadiness(
            status: ReadinessStatus.ready,
            blockers: [],
          ),
        ),
      ]);

  testWidgets('HomeScreen first paint settles with core tiles visible',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(400, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final container = makeContainer();
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: sisuMateLightTheme,
          darkTheme: sisuMateDarkTheme,
          themeMode: ThemeMode.dark,
          home: const HomeScreen(),
        ),
      ),
    );

    // Bounded pumps — must not hang waiting for infinite animation.
    for (var i = 0; i < 20; i++) {
      await tester.pump(const Duration(milliseconds: 16));
    }
    // Flush BannerAdWidget's 400ms deferred load timer.
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Shopping'), findsOneWidget);
    expect(find.text('Checklists'), findsOneWidget);
    expect(find.text('Games'), findsOneWidget);
    expect(find.text('Sisu Mate'), findsWidgets);
  });

  testWidgets('ShoppingScreen first paint settles without hanging',
      (tester) async {
    final container = makeContainer();
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: sisuMateLightTheme,
          darkTheme: sisuMateDarkTheme,
          themeMode: ThemeMode.dark,
          home: const ShoppingScreen(),
        ),
      ),
    );

    for (var i = 0; i < 20; i++) {
      await tester.pump(const Duration(milliseconds: 16));
    }
    await tester.pump(const Duration(milliseconds: 500));

    // TitleTile shows the module name.
    expect(find.text('Shopping & Spares'), findsOneWidget);
  });
}
