import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:sisu_mate/core/di.dart';
import 'package:sisu_mate/core/theme.dart';
import 'package:sisu_mate/data/drift/app_database.dart';
import 'package:sisu_mate/providers/passage_readiness_provider.dart';
import 'package:sisu_mate/services/revenuecat_service.dart';
import 'package:sisu_mate/services/suggestion_engine.dart';
import 'package:sisu_mate/ui/home/home_screen.dart';
import 'package:sisu_mate/ui/shopping/shopping_screen.dart';

import '../test/test_helpers/platform_mocks.dart';

/// TEST9: device/emulator integration suite.
///
/// Boots real screens with an in-memory Drift DB (same TEST6 stack) under the
/// [IntegrationTestWidgetsFlutterBinding]. Does **not** call production
/// `main()` (that needs live Supabase + dart-defines); those paths stay covered
/// by the manual adb/idb scripts.
///
/// Run:
/// ```
/// flutter test integration_test
/// # or on a device:
/// flutter test integration_test -d <deviceId>
/// ```
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

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

  testWidgets('home grid boots and shows core modules', (tester) async {
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
    // Bounded settle + flush BannerAdWidget deferred load (400ms).
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Shopping'), findsOneWidget);
    expect(find.text('Safety'), findsOneWidget);
    expect(find.text('Games'), findsOneWidget);
  });

  testWidgets('shopping screen boots empty without hanging', (tester) async {
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
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Shopping & Spares'), findsOneWidget);
  });
}
