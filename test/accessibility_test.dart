import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sisu_mate/core/di.dart';
import 'package:sisu_mate/core/theme.dart';
import 'package:sisu_mate/data/drift/app_database.dart';
import 'package:sisu_mate/providers/passage_readiness_provider.dart';
import 'package:sisu_mate/services/auth_service.dart';
import 'package:sisu_mate/services/revenuecat_service.dart';
import 'package:sisu_mate/services/suggestion_engine.dart';
import 'package:sisu_mate/ui/checklists/checklist_screen.dart';
import 'package:sisu_mate/ui/home/home_screen.dart';
import 'package:sisu_mate/ui/safety/safety_screen.dart';
import 'package:sisu_mate/ui/settings/settings_screen.dart';
import 'package:sisu_mate/ui/shopping/shopping_screen.dart';

import 'test_helpers/fake_auth_backend.dart';
import 'test_helpers/platform_mocks.dart';

/// TEST10 / TEST22: accessibility regression checks on key screens.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late FakeAuthBackend authBackend;

  setUp(() {
    mockConnectivityChannel();
    mockPathProviderChannel();
    db = AppDatabase.forTesting(NativeDatabase.memory());
    authBackend = FakeAuthBackend();
    RevenueCatService.debugProOverrideForTests = false;
  });

  tearDown(() async {
    RevenueCatService.debugProOverrideForTests = null;
    authBackend.dispose();
    await db.close();
  });

  Future<void> pumpWithContainer(
    WidgetTester tester,
    Widget home,
    ProviderContainer container, {
    Size surfaceSize = const Size(400, 1200),
  }) async {
    // Tall surface so the home module grid / list does not need scrolling
    // (a ListView(children:) still builds lazily against the viewport).
    await tester.binding.setSurfaceSize(surfaceSize);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: sisuMateLightTheme,
          darkTheme: sisuMateDarkTheme,
          themeMode: ThemeMode.dark,
          home: home,
        ),
      ),
    );
    await tester.pump();
    // BannerAdWidget schedules a 400ms deferred load — flush so no pending timers.
    await tester.pump(const Duration(milliseconds: 500));
  }

  Future<void> pumpScreen(
    WidgetTester tester,
    Widget home, {
    Size surfaceSize = const Size(400, 1200),
  }) async {
    final container = ProviderContainer(overrides: [
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
    await pumpWithContainer(tester, home, container, surfaceSize: surfaceSize);
  }

  /// Same base overrides as [pumpScreen] plus a fake auth backend, for
  /// screens (Settings) that watch [authStateProvider] directly.
  Future<void> pumpSettingsScreen(
    WidgetTester tester,
    Widget home, {
    Size surfaceSize = const Size(400, 1200),
  }) async {
    final container = ProviderContainer(overrides: [
      appDatabaseProvider.overrideWithValue(db),
      isProProvider.overrideWith((ref) => Stream.value(false)),
      boatSuggestionsProvider.overrideWith((ref) => const <BoatSuggestion>[]),
      passageReadinessProvider.overrideWith(
        (ref) => const PassageReadiness(
          status: ReadinessStatus.ready,
          blockers: [],
        ),
      ),
      authServiceProvider
          .overrideWith((ref) => AuthService(ref, backend: authBackend)),
    ]);
    await pumpWithContainer(tester, home, container, surfaceSize: surfaceSize);
  }

  testWidgets('HomeScreen meets labeled tap-target guideline', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpScreen(tester, const HomeScreen());

    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    handle.dispose();
  });

  testWidgets('ShoppingScreen meets labeled tap-target guideline',
      (tester) async {
    final handle = tester.ensureSemantics();
    await pumpScreen(tester, const ShoppingScreen());

    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    handle.dispose();
  });

  testWidgets('HomeScreen meets text-contrast guideline (dark theme)',
      (tester) async {
    final handle = tester.ensureSemantics();
    await pumpScreen(tester, const HomeScreen());

    await expectLater(tester, meetsGuideline(textContrastGuideline));
    handle.dispose();
  });

  testWidgets('HomeScreen module tiles are present as labeled text targets',
      (tester) async {
    final handle = tester.ensureSemantics();
    await pumpScreen(tester, const HomeScreen());

    for (final label in [
      'Shopping',
      'Cocktails',
      'Chef',
      'Safety',
      'Checklists',
      'Games',
    ]) {
      expect(find.text(label), findsOneWidget, reason: label);
    }
    handle.dispose();
  });

  // TEST22: A11y sweep — Safety, Checklists, Settings.

  testWidgets('SafetyScreen meets labeled tap-target guideline',
      (tester) async {
    final handle = tester.ensureSemantics();
    await pumpScreen(tester, const SafetyScreen());

    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    handle.dispose();
  });

  testWidgets('SafetyScreen meets text-contrast guideline (dark theme)',
      (tester) async {
    final handle = tester.ensureSemantics();
    await pumpScreen(tester, const SafetyScreen());

    await expectLater(tester, meetsGuideline(textContrastGuideline));
    handle.dispose();
  });

  testWidgets('ChecklistScreen meets labeled tap-target guideline',
      (tester) async {
    final handle = tester.ensureSemantics();
    await pumpScreen(tester, const ChecklistScreen());

    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    handle.dispose();
  });

  testWidgets('ChecklistScreen meets text-contrast guideline (dark theme)',
      (tester) async {
    final handle = tester.ensureSemantics();
    await pumpScreen(tester, const ChecklistScreen());

    await expectLater(tester, meetsGuideline(textContrastGuideline));
    handle.dispose();
  });

  testWidgets('SettingsScreen meets labeled tap-target guideline',
      (tester) async {
    final handle = tester.ensureSemantics();
    await pumpSettingsScreen(
      tester,
      const SettingsScreen(),
      // Settings' ListView is long enough that a shorter viewport leaves
      // late sections (e.g. Data Management) unbuilt (lazy sliver list).
      surfaceSize: const Size(400, 2400),
    );

    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    handle.dispose();
  });

  testWidgets('SettingsScreen meets text-contrast guideline (dark theme)',
      (tester) async {
    final handle = tester.ensureSemantics();
    await pumpSettingsScreen(
      tester,
      const SettingsScreen(),
      // Settings' ListView is long enough that a shorter viewport leaves
      // late sections (e.g. Data Management) unbuilt (lazy sliver list).
      surfaceSize: const Size(400, 2400),
    );

    await expectLater(tester, meetsGuideline(textContrastGuideline));
    handle.dispose();
  });

  testWidgets(
      'SettingsScreen sections are present as labeled text targets',
      (tester) async {
    final handle = tester.ensureSemantics();
    await pumpSettingsScreen(
      tester,
      const SettingsScreen(),
      // Settings' ListView is long enough that a shorter viewport leaves
      // late sections (e.g. Data Management) unbuilt (lazy sliver list).
      surfaceSize: const Size(400, 2400),
    );

    for (final label in [
      'Account',
      'Boats',
      'Appearance',
      'Units',
      'Email & Sharing',
      'Data Management',
    ]) {
      expect(find.text(label), findsOneWidget, reason: label);
    }
    handle.dispose();
  });
}
