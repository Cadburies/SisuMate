import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sisu_mate/core/di.dart';
import 'package:sisu_mate/data/drift/app_database.dart';
import 'package:sisu_mate/services/revenuecat_service.dart';
import 'package:sisu_mate/ui/checklists/checklist_screen.dart';
import 'package:sisu_mate/ui/maintenance/maintenance_screen.dart';
import 'package:sisu_mate/ui/safety/safety_screen.dart';

import 'test_helpers/platform_mocks.dart';

/// #210: the group-list search on Maintenance/Checklists/Safety used to
/// filter by `group.title` only. This seeds a group whose title has no
/// overlap with the search term, but whose item DOES — confirming the
/// search now also matches item title/name/description, and that the
/// matching tile explains why (a "Matched: ..." hint), not just Maintenance
/// but consistently across all three screens.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late AppDatabase db;

  setUp(() {
    mockConnectivityChannel();
    mockPathProviderChannel();
    mockSharedPreferencesChannel();
    db = AppDatabase.forTesting(NativeDatabase.memory());
    RevenueCatService.debugProOverrideForTests = true;
  });

  tearDown(() async {
    RevenueCatService.debugProOverrideForTests = null;
    await db.close();
  });

  Future<void> seed({
    required String appType,
    required bool itemHidden,
  }) async {
    await db.into(db.checklistGroups).insert(
          ChecklistGroupsCompanion.insert(
            supabaseId: const Value('grp_engine'),
            boatSupabaseId: const Value('boat_1'),
            appType: Value(appType),
            title: const Value('Engine Room'),
          ),
        );
    await db.into(db.checklistItems).insert(
          ChecklistItemsCompanion.insert(
            supabaseId: const Value('itm_valve'),
            boatSupabaseId: const Value('boat_1'),
            groupSupabaseId: const Value('grp_engine'),
            title: const Value('Check valve clearances/gaps'),
            name: const Value('Check valve clearances/gaps'),
            isHidden: Value(itemHidden),
          ),
        );
    // A second, unrelated group that must NOT show up for this search.
    await db.into(db.checklistGroups).insert(
          ChecklistGroupsCompanion.insert(
            supabaseId: const Value('grp_deck'),
            boatSupabaseId: const Value('boat_1'),
            appType: Value(appType),
            title: const Value('Deck Hardware'),
          ),
        );
    await db.into(db.checklistItems).insert(
          ChecklistItemsCompanion.insert(
            supabaseId: const Value('itm_winch'),
            boatSupabaseId: const Value('boat_1'),
            groupSupabaseId: const Value('grp_deck'),
            title: const Value('Grease winches'),
            name: const Value('Grease winches'),
          ),
        );
  }

  Future<void> pumpAndSearch(
    WidgetTester tester,
    Widget screen,
    String query,
  ) async {
    final container = ProviderContainer(overrides: [
      appDatabaseProvider.overrideWithValue(db),
      isProProvider.overrideWith((ref) => Stream.value(true)),
    ]);
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(home: screen),
      ),
    );
    await tester.pump();
    await tester.pump();
    await tester.enterText(find.byType(TextField), query);
    await tester.pump();
    await tester.pump();
  }

  testWidgets('Maintenance: searching "gaps" finds a group by item content',
      (tester) async {
    await seed(appType: 'maintenance', itemHidden: false);
    await pumpAndSearch(tester, const MaintenanceScreen(), 'gaps');

    expect(find.text('Engine Room'), findsOneWidget,
        reason: 'title has no "gaps" but its item does');
    expect(find.text('Deck Hardware'), findsNothing,
        reason: 'unrelated group must be filtered out');
    expect(find.textContaining('Matched: Check valve clearances/gaps'),
        findsOneWidget);
  });

  testWidgets('Checklists: same content-search behavior as Maintenance',
      (tester) async {
    await seed(appType: 'checklist', itemHidden: false);
    await pumpAndSearch(tester, const ChecklistScreen(), 'gaps');

    expect(find.text('Engine Room'), findsOneWidget);
    expect(find.text('Deck Hardware'), findsNothing);
    expect(find.textContaining('Matched: Check valve clearances/gaps'),
        findsOneWidget);
  });

  testWidgets('Safety: same content-search behavior, alongside the '
      'existing completion-state filter', (tester) async {
    await seed(appType: 'safety', itemHidden: false);
    await pumpAndSearch(tester, const SafetyScreen(), 'gaps');

    expect(find.text('Engine Room'), findsOneWidget);
    expect(find.text('Deck Hardware'), findsNothing);
    expect(find.textContaining('Matched: Check valve clearances/gaps'),
        findsOneWidget);
  });

  testWidgets('a title match does not show a "Matched:" hint (only '
      'content-only matches need explaining)', (tester) async {
    await seed(appType: 'maintenance', itemHidden: false);
    await pumpAndSearch(tester, const MaintenanceScreen(), 'Engine');

    expect(find.text('Engine Room'), findsOneWidget);
    expect(find.textContaining('Matched:'), findsNothing);
  });

  testWidgets('hidden items are excluded from content search',
      (tester) async {
    await seed(appType: 'maintenance', itemHidden: true);
    await pumpAndSearch(tester, const MaintenanceScreen(), 'gaps');

    expect(find.text('Engine Room'), findsNothing,
        reason: 'the only matching item is hidden, so the group should not '
            'surface via content search');
    expect(find.text('No matching lists'), findsOneWidget);
  });
}
