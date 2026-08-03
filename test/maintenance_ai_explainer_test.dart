import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sisu_mate/core/di.dart';
import 'package:sisu_mate/data/drift/app_database.dart';
import 'package:sisu_mate/models/models.dart';
import 'package:sisu_mate/services/revenuecat_service.dart';
import 'package:sisu_mate/ui/maintenance/maintenance_ai_explainer_dialog.dart';
import 'package:sisu_mate/ui/maintenance/maintenance_items_screen.dart';

import 'test_helpers/platform_mocks.dart';

/// #18 (first LLM product use) / #208 (AI kept visually separate from
/// offline actions): the AI explainer badge is distinct from
/// Complete/Hide, and — with no key configured (the default, unconfigured
/// state) — the dialog clearly says so rather than silently failing.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late AppDatabase db;

  const groupId = 'grp_maint';
  const itemId = 'maint_bilge';

  setUp(() {
    mockConnectivityChannel();
    mockPathProviderChannel();
    mockSharedPreferencesChannel();
    db = AppDatabase.forTesting(NativeDatabase.memory());
    // Free (not Pro) here specifically — unlike #179's test, this one sets a
    // real active-boat userSettings row so activeBoatProvider resolves,
    // which also makes SyncService.ensureStarted() actually proceed if
    // RevenueCatService reports Pro, leaving a periodic timer pending past
    // the test's teardown. isProProvider below still drives the UI as Pro.
    RevenueCatService.debugProOverrideForTests = false;
  });

  tearDown(() async {
    RevenueCatService.debugProOverrideForTests = null;
    await db.close();
  });

  Future<ProviderContainer> pumpScreen(WidgetTester tester) async {
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
    await db.into(db.checklistGroups).insert(ChecklistGroupsCompanion.insert(
          supabaseId: const Value(groupId),
          boatSupabaseId: const Value('boat_1'),
          appType: const Value('maintenance'),
          title: const Value('Engine Room'),
        ));
    await db.into(db.checklistItems).insert(ChecklistItemsCompanion.insert(
          supabaseId: const Value(itemId),
          boatSupabaseId: const Value('boat_1'),
          groupSupabaseId: const Value(groupId),
          title: const Value('Check bilge pump'),
          name: const Value('Check bilge pump'),
          description: const Value('Verify the automatic float switch cycles'),
        ));

    final group = ChecklistGroup()
      ..supabaseId = groupId
      ..boatSupabaseId = 'boat_1'
      ..appType = 'maintenance'
      ..title = 'Engine Room';

    final container = ProviderContainer(overrides: [
      appDatabaseProvider.overrideWithValue(db),
      isProProvider.overrideWith((ref) => Stream.value(true)),
    ]);
    addTearDown(container.dispose);

    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: MaterialApp(home: MaintenanceItemsScreen(group: group)),
    ));
    await tester.pump();
    await tester.pump();
    return container;
  }

  testWidgets('the AI badge renders distinct from Complete/Hide icons',
      (tester) async {
    await pumpScreen(tester);

    expect(find.byIcon(Icons.auto_awesome), findsOneWidget,
        reason: '#208: AI entry point must have its own icon, not reuse '
            'Complete/Hide iconography');
  });

  testWidgets('tapping the AI badge opens a menu, not the item detail '
      'viewer directly', (tester) async {
    await pumpScreen(tester);

    await tester.tap(find.byIcon(Icons.auto_awesome));
    await tester.pump();

    expect(find.text('Explain this task'), findsOneWidget);
    expect(find.text('Check warranty coverage'), findsOneWidget,
        reason: '#222: warranty check joins the explainer on the same AI '
            'badge instead of a second competing badge');
    expect(find.text('Find a compatible part near me'), findsOneWidget,
        reason: '#217: part sourcing joins the same AI badge too');
  });

  testWidgets('picking "Explain this task" from the AI menu opens the '
      'explainer dialog', (tester) async {
    await pumpScreen(tester);

    await tester.tap(find.byIcon(Icons.auto_awesome));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Explain this task'));
    await tester.pumpAndSettle();

    expect(find.byType(MaintenanceAiExplainerDialog), findsOneWidget);
    expect(find.textContaining('AI: Check bilge pump'), findsOneWidget);
  });

  testWidgets(
      'with no key configured, the dialog says so instead of silently '
      'failing', (tester) async {
    await pumpScreen(tester);

    await tester.tap(find.byIcon(Icons.auto_awesome));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Explain this task'));
    await tester.pumpAndSettle();
    // Resolve the async explain() call (no-key path returns immediately,
    // no real network involved).
    await tester.pump();
    await tester.pump();

    expect(find.textContaining('No AI API key is configured'), findsOneWidget);
    expect(find.text('Go to Settings'), findsOneWidget);
  });
}
