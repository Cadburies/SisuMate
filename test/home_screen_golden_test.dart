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

import 'test_helpers/platform_mocks.dart';

/// TEST24: small, stable golden set for the home screen only — catches
/// theme/layout disasters (e.g. a colour token regression) without the
/// sprawl of full-app screenshot coverage.
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

  Future<void> pumpHome(WidgetTester tester, ThemeMode mode) async {
    await tester.binding.setSurfaceSize(const Size(400, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetDevicePixelRatio);

    final container = makeContainer();
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: sisuMateLightTheme,
          darkTheme: sisuMateDarkTheme,
          themeMode: mode,
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
  }

  testWidgets('HomeScreen golden — dark theme', (tester) async {
    await pumpHome(tester, ThemeMode.dark);

    await expectLater(
      find.byType(HomeScreen),
      matchesGoldenFile('goldens/home_screen_dark.png'),
    );
  });

  testWidgets('HomeScreen golden — light theme', (tester) async {
    await pumpHome(tester, ThemeMode.light);

    await expectLater(
      find.byType(HomeScreen),
      matchesGoldenFile('goldens/home_screen_light.png'),
    );
  });
}
