import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sisu_mate/core/app_router.dart';
import 'package:sisu_mate/core/di.dart';
import 'package:sisu_mate/core/theme.dart';
import 'package:sisu_mate/data/drift/app_database.dart';
import 'package:sisu_mate/data/seed/seed_expansion_catalog.dart';
import 'package:sisu_mate/providers/passage_readiness_provider.dart';
import 'package:sisu_mate/services/database_service.dart';
import 'package:sisu_mate/services/revenuecat_service.dart';
import 'package:sisu_mate/services/suggestion_engine.dart';
import 'package:sisu_mate/services/sync_service.dart';

import '../../tool/feature_map.dart' as fm;
import '../test_helpers/platform_mocks.dart';

/// Feature Map host reach executor (#354). `reach(tester, '<id>')` reads
/// `.ai_context/feature_map/<id>.md`, applies its `needs`, boots the real
/// router at Home (or onboarding for `launch/`) over a seeded in-memory DB,
/// then runs every `reach` step exactly as FORMAT.md defines them. A step
/// whose target is missing or not unique fails with the step named.
class FmApp {
  final AppDatabase db;
  final ProviderContainer container;
  final GoRouter router;
  FmApp(this.db, this.container, this.router);
}

fm.Feature loadFeature(String id) {
  final file = File('${fm.featureMapRoot}/$id.md');
  if (!file.existsSync()) throw StateError('no feature file for "$id"');
  return fm.parseFeature(id, file.readAsStringSync());
}

/// Bounded pumps: ads, jiggle and progress animations never settle.
Future<void> settle(WidgetTester tester) async {
  await tester.pump(const Duration(milliseconds: 100));
  await tester.pump(const Duration(milliseconds: 500));
}

/// Boots the app for [id] and runs its reach steps.
///
/// [tier] overrides `needs: tier=` (default Pro, so gates don't block reach;
/// pass `'free'` for Free-path variants). [setup] runs after seeding for extra
/// rows. [overrides] are appended to the default provider overrides unless
/// [defaultOverrides] is false (Riverpod rejects overriding one provider twice).
/// [steps] limits how many reach steps run (e.g. all but the last).
Future<FmApp> reach(
  WidgetTester tester,
  String id, {
  String? tier,
  bool seed = true,
  bool expansionSeed = true,
  Future<void> Function(AppDatabase db)? setup,
  List<Object> overrides = const [],
  bool defaultOverrides = true,
  int? steps,
}) async {
  final feature = loadFeature(id);
  final needs = feature.needs;
  if (needs['platform'] == 'device') {
    throw StateError('$id needs platform=device: use scripts/fm.sh $id --device <id>');
  }
  final isPro = (tier ?? needs['tier'] ?? 'pro') == 'pro';
  final launch = feature.root == 'launch';
  final onboardingSeen = (needs['onboarding'] ?? (launch ? 'unseen' : 'seen')) == 'seen';

  mockConnectivityChannel(online: needs['network'] != 'offline');
  mockPathProviderChannel();
  SharedPreferences.setMockInitialValues({'onboarding_seen_v1': onboardingSeen});
  RevenueCatService.debugProOverrideForTests = isPro;
  addTearDown(() => RevenueCatService.debugProOverrideForTests = null);

  final db = AppDatabase.forTesting(NativeDatabase.memory());
  AppDatabase.setInstanceForTesting(db);
  addTearDown(db.close);
  if (seed) {
    // Same path as a real fresh install: settings row + bundled seed + baseline.
    await tester.runAsync(DatabaseService().init);
    if (expansionSeed) {
      await tester.runAsync(() => seedExpansionCatalog('00000000-0000-0000-0000-000000000000'));
    }
  }
  if (setup != null) await tester.runAsync(() => setup(db));

  await tester.binding.setSurfaceSize(const Size(800, 1400));
  addTearDown(() => tester.binding.setSurfaceSize(null));

  final container = ProviderContainer(overrides: [
    appDatabaseProvider.overrideWithValue(db),
    isProProvider.overrideWith((ref) => Stream.value(isPro)),
    // Host runs never talk to Supabase; a started SyncService would also leave
    // its 30 s queue-monitor timer pending at test end.
    syncServiceProvider.overrideWith((ref) => _HostSyncService(ref)),
    if (defaultOverrides) ...[
      boatSuggestionsProvider.overrideWith((ref) => const <BoatSuggestion>[]),
      passageReadinessProvider.overrideWith(
        (ref) => const PassageReadiness(status: ReadinessStatus.ready, blockers: []),
      ),
    ],
    ...overrides.cast(),
  ]);
  addTearDown(container.dispose);

  final router = createAppRouter(
    initialLocation: launch && !onboardingSeen ? AppRoutes.onboarding : AppRoutes.home,
  );
  await tester.pumpWidget(UncontrolledProviderScope(
    container: container,
    child: MaterialApp.router(
      theme: sisuMateLightTheme,
      darkTheme: sisuMateDarkTheme,
      themeMode: ThemeMode.dark,
      routerConfig: router,
    ),
  ));
  await settle(tester);

  final all = feature.reachSteps;
  for (final step in all.take(steps ?? all.length)) {
    await runStep(tester, step);
  }
  return FmApp(db, container, router);
}

/// Runs one FORMAT.md reach step.
Future<void> runStep(WidgetTester tester, String step) async {
  if (step == 'back') {
    final back = find.byTooltip('Back').hitTestable();
    if (back.evaluate().isNotEmpty) {
      await tester.tap(back.first);
    } else {
      await tester.pageBack();
    }
    await settle(tester);
    return;
  }
  final error = fm.checkReachStep(step);
  if (error != null) fail('reach: $error');
  final colon = step.indexOf(':');
  final verb = step.substring(0, colon);
  final arg = step.substring(colon + 1);
  switch (verb) {
    case 'text':
      await _act(tester, find.text(arg), step);
    case 'tip':
      await _act(tester, find.byTooltip(arg), step);
    case 'label':
      await _act(tester, find.bySemanticsLabel(arg), step);
    case 'long':
      final byText = find.text(arg);
      await _act(tester, byText.evaluate().isNotEmpty ? byText : find.bySemanticsLabel(arg), step,
          long: true);
    case 'swipe':
      final i = arg.lastIndexOf(':');
      final row = await _reveal(tester, find.text(arg.substring(0, i)), step);
      final action = find.text(arg.substring(i + 1));
      await tester.drag(row, const Offset(-300, 0));
      await settle(tester);
      if (action.hitTestable().evaluate().isEmpty) {
        await tester.drag(row, const Offset(600, 0));
        await settle(tester);
      }
      await _act(tester, action, step);
    case 'type':
      final i = arg.indexOf('=');
      final label = arg.substring(0, i);
      var field = find.widgetWithText(TextField, label);
      if (field.evaluate().isEmpty) field = find.widgetWithText(TextFormField, label);
      final target = await _reveal(tester, field, step);
      await tester.enterText(target, arg.substring(i + 1));
      await settle(tester);
    case 'wait':
      for (var i = 0; i < 50 && find.text(arg).evaluate().isEmpty; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      if (find.text(arg).evaluate().isEmpty) fail('reach "$step": "$arg" never appeared');
  }
}

Future<void> _act(WidgetTester tester, Finder finder, String step, {bool long = false}) async {
  final target = await _reveal(tester, finder, step);
  if (long) {
    await tester.longPress(target);
  } else {
    await tester.tap(target);
  }
  await settle(tester);
}

/// Scrolls until exactly one hit-testable match exists; fails otherwise.
Future<Finder> _reveal(WidgetTester tester, Finder finder, String step) async {
  Finder hittable() => finder.hitTestable();
  if (hittable().evaluate().isEmpty) {
    final scrollables = find.byType(Scrollable).evaluate().where((e) {
      final dir = (e.widget as Scrollable).axisDirection;
      return dir == AxisDirection.down || dir == AxisDirection.up;
    }).toList();
    for (final s in scrollables) {
      if (hittable().evaluate().isNotEmpty) break;
      try {
        await tester.scrollUntilVisible(finder, 200,
            scrollable: find.byWidget(s.widget), maxScrolls: 40);
        await tester.pump();
      } on StateError {
        // Target not in this scrollable; try the next one.
      } on TestFailure {
        // Same: scrolled to the end without finding it.
      }
    }
  }
  final n = hittable().evaluate().length;
  if (n == 0) fail('reach "$step": target not found on screen');
  if (n > 1) fail('reach "$step": $n matches; targets must be unique (add a tooltip/semanticsLabel)');
  return hittable();
}

class _HostSyncService extends SyncService {
  _HostSyncService(super.ref);

  @override
  Future<void> ensureStarted() async {}
}
