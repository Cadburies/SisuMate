import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sisu_mate/core/di.dart';
import 'package:sisu_mate/data/drift/app_database.dart';
import 'package:sisu_mate/services/revenuecat_service.dart';
import 'package:sisu_mate/ui/maintenance/maintenance_hours_screen.dart';
import 'package:sisu_mate/ui/maintenance/maintenance_risk_triage_dialog.dart';

import 'test_helpers/platform_mocks.dart';

/// #216 (supersedes the maintenance half of #18) / #208: the risk-triage AI
/// entry point on the maintenance hours/service log screen must be visually
/// distinct from the offline add/edit actions, and — with no key configured
/// (the default) — must say so plainly rather than silently failing.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late AppDatabase db;

  setUp(() {
    mockConnectivityChannel();
    mockPathProviderChannel();
    mockSharedPreferencesChannel();
    db = AppDatabase.forTesting(NativeDatabase.memory());
    RevenueCatService.debugProOverrideForTests = false;
  });

  tearDown(() async {
    RevenueCatService.debugProOverrideForTests = null;
    await db.close();
  });

  Future<ProviderContainer> pumpScreen(WidgetTester tester,
      {bool withTask = true}) async {
    await db.into(db.boats).insert(BoatsCompanion.insert(
          supabaseId: const Value('boat_1'),
          name: const Value('Sisu'),
        ));
    await db.into(db.userSettingsTable).insert(
          UserSettingsTableCompanion.insert(
            id: const Value(1),
            activeBoatSupabaseId: const Value('boat_1'),
          ),
        );
    if (withTask) {
      await db.into(db.maintenanceTasks).insert(
            MaintenanceTasksCompanion.insert(
              supabaseId: const Value('maint_1'),
              boatSupabaseId: const Value('boat_1'),
              description: const Value('Replace impeller'),
              intervalHours: const Value(500),
            ),
          );
    }

    final container = ProviderContainer(overrides: [
      appDatabaseProvider.overrideWithValue(db),
      isProProvider.overrideWith((ref) => Stream.value(true)),
    ]);
    addTearDown(container.dispose);

    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(home: MaintenanceHoursScreen()),
    ));
    await tester.pump();
    await tester.pump();
    return container;
  }

  testWidgets('the AI badge renders distinct from the add/edit FAB',
      (tester) async {
    await pumpScreen(tester);

    expect(find.byIcon(Icons.auto_awesome), findsOneWidget,
        reason: '#208: AI entry point must have its own icon, not reuse '
            'the FAB add icon');
    expect(find.byIcon(Icons.add), findsOneWidget);
  });

  testWidgets('the AI badge is disabled when the backlog is empty',
      (tester) async {
    await pumpScreen(tester, withTask: false);

    final button = tester.widget<IconButton>(find.ancestor(
      of: find.byIcon(Icons.auto_awesome),
      matching: find.byType(IconButton),
    ));
    expect(button.onPressed, isNull);
  });

  testWidgets('tapping the AI badge opens the risk triage dialog',
      (tester) async {
    await pumpScreen(tester);

    await tester.tap(find.byIcon(Icons.auto_awesome));
    await tester.pumpAndSettle();

    expect(find.byType(MaintenanceRiskTriageDialog), findsOneWidget);
    expect(find.text('Maintenance risk triage'), findsOneWidget);
    // #289 — local report is immediate (no key required).
    expect(find.textContaining('Offline risk triage'), findsOneWidget);
    expect(find.text('Explain with AI'), findsOneWidget);
  });

  testWidgets(
      'with no key configured, optional AI path says so instead of blocking '
      'the local report', (tester) async {
    await pumpScreen(tester);

    await tester.tap(find.byIcon(Icons.auto_awesome));
    await tester.pumpAndSettle();

    expect(find.textContaining('Offline risk triage'), findsOneWidget);
    await tester.tap(find.text('Explain with AI'));
    await tester.pump();
    await tester.pump();
    await tester.pump();

    expect(find.textContaining('No AI API key is configured'), findsOneWidget);
    expect(find.text('Go to Settings'), findsOneWidget);
  });
}
