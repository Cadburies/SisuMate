import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sisu_mate/core/app_router.dart';
import 'package:sisu_mate/core/di.dart';
import 'package:sisu_mate/providers/passage_readiness_provider.dart';
import 'package:sisu_mate/services/suggestion_engine.dart';

import '_reach.dart';

/// Feature Map scripts for `.ai_context/feature_map/home.md` and `home/*`
/// shell features (tiles, cards, reorder, main menu). Test names are feature
/// ids (`scripts/fm.sh <id>`).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('home', (tester) async {
    await reach(tester, 'home');
    expect(find.text('Shopping'), findsOneWidget);
    expect(find.text('Safety'), findsOneWidget);
  });

  testWidgets('home/readiness', (tester) async {
    await reach(tester, 'home/readiness');
    expect(find.text('Ready for passage'), findsOneWidget);
  });

  testWidgets('home/suggestions', (tester) async {
    await reach(tester, 'home/suggestions', defaultOverrides: false, overrides: [
      authStateProvider.overrideWith((ref) => Stream.value(null)),
      passageReadinessProvider.overrideWith(
        (ref) => const PassageReadiness(status: ReadinessStatus.ready, blockers: []),
      ),
      boatSuggestionsProvider.overrideWith((ref) => const [
            BoatSuggestion(
              id: 'fm',
              title: 'Engine service due',
              detail: '250-hour service is overdue',
              severity: SuggestionSeverity.urgent,
              routePath: AppRoutes.maintenance,
            ),
          ]),
    ]);
    expect(find.text('Suggestions'), findsOneWidget);
    await runStep(tester, 'text:Engine service due');
    expect(find.text('Maintenance'), findsOneWidget);
  });

  testWidgets('home/reorder', (tester) async {
    await reach(tester, 'home/reorder');
    expect(find.text('Done'), findsOneWidget);
    // In edit mode a tile tap must not navigate.
    await tester.tap(find.text('Shopping'));
    await settle(tester);
    expect(find.text('Shopping & Spares'), findsNothing);
    await runStep(tester, 'text:Done');
    expect(find.text('Done'), findsNothing);
  });

  testWidgets('home/drawer', (tester) async {
    await reach(tester, 'home/drawer');
    expect(find.text('Settings'), findsOneWidget);
    expect(find.text('Data Management'), findsOneWidget);
  });

  testWidgets('home/drawer/synchronise', (tester) async {
    await reach(tester, 'home/drawer/synchronise');
    await runStep(tester, 'wait:Recipe counts updated');
  });

  testWidgets('home/drawer/sync_status', (tester) async {
    await reach(tester, 'home/drawer/sync_status');
    expect(find.text('Pending outbox'), findsOneWidget);
    expect(find.text('Force flush queue'), findsOneWidget);
  });

  testWidgets('home/drawer/sync_conflicts', (tester) async {
    await reach(tester, 'home/drawer/sync_conflicts');
    expect(find.textContaining('No pending conflicts.'), findsOneWidget);
  });

  testWidgets('home/drawer/reset_to_factory', (tester) async {
    await reach(tester, 'home/drawer/reset_to_factory');
    expect(find.text('Factory Reset'), findsOneWidget);
    await runStep(tester, 'text:Cancel');
    expect(find.text('Factory Reset'), findsNothing);
  });

  testWidgets('home/drawer/upgrade', (tester) async {
    await reach(tester, 'home/drawer/upgrade');
    expect(find.text('Upgrade to Sisu Mate Pro'), findsOneWidget);
  });

  testWidgets('home/drawer/upgrade [pro]', (tester) async {
    await reach(tester, 'home/drawer', tier: 'pro');
    final tile = tester.widget<ListTile>(find.widgetWithText(ListTile, 'Upgrade to Pro'));
    expect(tile.enabled, isFalse);
  });

  testWidgets('home/drawer/about', (tester) async {
    await reach(tester, 'home/drawer/about');
    expect(find.text('About Sisu Mate'), findsOneWidget);
  });
}
