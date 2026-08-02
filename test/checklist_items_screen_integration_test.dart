import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sisu_mate/core/di.dart';
import 'package:sisu_mate/data/drift/app_database.dart';
import 'package:sisu_mate/models/models.dart';
import 'package:sisu_mate/services/revenuecat_service.dart';
import 'package:sisu_mate/ui/checklists/checklist_items_screen.dart';

import 'test_helpers/platform_mocks.dart';

/// TEST17: checklist **complete → Drift** via the real screen + provider tree
/// (same TEST6 pattern as shopping_screen_integration_test.dart).
///
/// Completing an item uses swipe-left → "Complete" on [ChecklistItemTile],
/// which calls [ChecklistRepositoryImpl.toggleComplete] when Pro.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late AppDatabase db;

  const groupId = 'grp_dep';
  const itemId = 'chk_bilge';

  final group = ChecklistGroup()
    ..supabaseId = groupId
    ..boatSupabaseId = 'boat_1'
    ..appType = 'checklist'
    ..title = 'Pre-departure'
    ..isBundled = false;

  setUp(() {
    mockConnectivityChannel();
    mockPathProviderChannel();
    mockSharedPreferencesChannel();
    db = AppDatabase.forTesting(NativeDatabase.memory());
    // Free by default; Pro tests flip the override.
    RevenueCatService.debugProOverrideForTests = false;
  });

  tearDown(() async {
    RevenueCatService.debugProOverrideForTests = null;
    await db.close();
  });

  Future<void> seedGroupAndItem({bool completed = false}) async {
    await db.into(db.checklistGroups).insert(
          ChecklistGroupsCompanion.insert(
            supabaseId: const Value(groupId),
            boatSupabaseId: const Value('boat_1'),
            appType: const Value('checklist'),
            title: const Value('Pre-departure'),
          ),
        );
    await db.into(db.checklistItems).insert(
          ChecklistItemsCompanion.insert(
            supabaseId: const Value(itemId),
            boatSupabaseId: const Value('boat_1'),
            groupSupabaseId: const Value(groupId),
            title: const Value('Check bilge pump'),
            name: const Value('Check bilge pump'),
            isCompleted: Value(completed),
          ),
        );
  }

  Future<ProviderContainer> pumpItems(
    WidgetTester tester, {
    bool isPro = true,
  }) async {
    final container = ProviderContainer(overrides: [
      appDatabaseProvider.overrideWithValue(db),
      isProProvider.overrideWith((ref) => Stream.value(isPro)),
    ]);
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: ChecklistItemsScreen(group: group),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    return container;
  }

  /// Swipe left on the item row to reveal the Complete action, then tap it.
  Future<void> swipeAndTapComplete(WidgetTester tester) async {
    final title = find.text('Check bilge pump');
    expect(title, findsOneWidget);
    await tester.drag(title, const Offset(-400, 0));
    await tester.pumpAndSettle();
    final complete = find.text('Complete');
    expect(complete, findsOneWidget);
    await tester.tap(complete);
    await tester.pumpAndSettle();
  }

  testWidgets(
      'a row seeded into Drift renders through the real repository + provider '
      'stack', (tester) async {
    await seedGroupAndItem();
    await pumpItems(tester);

    expect(find.text('Pre-departure'), findsOneWidget);
    expect(find.text('Check bilge pump'), findsOneWidget);
  });

  testWidgets(
      'Pro: swipe Complete writes isCompleted=true into Drift via '
      'ChecklistRepositoryImpl.toggleComplete', (tester) async {
    await seedGroupAndItem(completed: false);
    await pumpItems(tester, isPro: true);

    await swipeAndTapComplete(tester);

    // UI still shows the title (completed items stay visible by default).
    expect(find.text('Check bilge pump'), findsOneWidget);

    final rows = await db.select(db.checklistItems).get();
    expect(rows, hasLength(1));
    expect(rows.single.supabaseId, itemId);
    expect(rows.single.isCompleted, isTrue,
        reason: 'complete must persist in Drift, not only local widget state');
    expect(rows.single.completedAt, isNotNull);
  });

  testWidgets(
      'Free: swipe Complete does not mark the item done in Drift '
      '(Pro-gated list complete)', (tester) async {
    await seedGroupAndItem(completed: false);
    await pumpItems(tester, isPro: false);

    await swipeAndTapComplete(tester);

    // Free path shows a snackbar; allow interstitial async delay to finish.
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pumpAndSettle();

    final rows = await db.select(db.checklistItems).get();
    expect(rows.single.isCompleted, isFalse,
        reason: 'Free tier list-level complete must not mutate Drift');
    expect(
      find.textContaining('Sisu Pro'),
      findsWidgets,
    );
  });

  // #205: "Complete all" / "Clear all" bulk drawer actions.
  const bulkVisibleId = 'chk_visible';
  const bulkHiddenId = 'chk_hidden';

  Future<void> seedTwoItems({
    required bool visibleCompleted,
    required bool hiddenCompleted,
  }) async {
    await db.into(db.checklistGroups).insert(
          ChecklistGroupsCompanion.insert(
            supabaseId: const Value(groupId),
            boatSupabaseId: const Value('boat_1'),
            appType: const Value('checklist'),
            title: const Value('Pre-departure'),
          ),
        );
    await db.into(db.checklistItems).insert(
          ChecklistItemsCompanion.insert(
            supabaseId: const Value(bulkVisibleId),
            boatSupabaseId: const Value('boat_1'),
            groupSupabaseId: const Value(groupId),
            title: const Value('Check bilge pump'),
            name: const Value('Check bilge pump'),
            isCompleted: Value(visibleCompleted),
          ),
        );
    await db.into(db.checklistItems).insert(
          ChecklistItemsCompanion.insert(
            supabaseId: const Value(bulkHiddenId),
            boatSupabaseId: const Value('boat_1'),
            groupSupabaseId: const Value(groupId),
            title: const Value('Hidden item'),
            name: const Value('Hidden item'),
            isCompleted: Value(hiddenCompleted),
            isHidden: const Value(true),
          ),
        );
  }

  Future<void> openDrawerAndTap(WidgetTester tester, String label) async {
    final scaffold = tester.state<ScaffoldState>(find.byType(Scaffold));
    scaffold.openEndDrawer();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    final tile = find.text(label);
    await tester.ensureVisible(tile);
    await tester.pumpAndSettle();
    await tester.tap(tile);
    await tester.pumpAndSettle();
    // Confirmation dialog — tap the matching confirm button (scoped to the
    // dialog since the drawer tile with the same label is still in the tree
    // behind the modal barrier).
    await tester.tap(find.descendant(
      of: find.byType(AlertDialog),
      matching: find.text(label),
    ));
    await tester.pumpAndSettle();
  }

  testWidgets(
      '#205: "Complete all" marks every visible item done, leaves hidden '
      'items untouched (via ChecklistRepositoryImpl.completeAll)',
      (tester) async {
    await seedTwoItems(visibleCompleted: false, hiddenCompleted: false);
    await pumpItems(tester, isPro: true);

    await openDrawerAndTap(tester, 'Complete All');

    final rows = await db.select(db.checklistItems).get();
    final visible = rows.singleWhere((r) => r.supabaseId == bulkVisibleId);
    final hidden = rows.singleWhere((r) => r.supabaseId == bulkHiddenId);
    expect(visible.isCompleted, isTrue,
        reason: 'Complete all must mark visible incomplete items done');
    expect(hidden.isCompleted, isFalse,
        reason: 'Complete all must not affect hidden items');
  });

  testWidgets(
      '#205: "Clear all" marks every visible item not-done, leaves hidden '
      'items untouched (via ChecklistRepositoryImpl.uncompleteAll)',
      (tester) async {
    await seedTwoItems(visibleCompleted: true, hiddenCompleted: true);
    await pumpItems(tester, isPro: true);

    await openDrawerAndTap(tester, 'Clear All');

    final rows = await db.select(db.checklistItems).get();
    final visible = rows.singleWhere((r) => r.supabaseId == bulkVisibleId);
    final hidden = rows.singleWhere((r) => r.supabaseId == bulkHiddenId);
    expect(visible.isCompleted, isFalse,
        reason: 'Clear all must mark visible completed items not-done');
    expect(hidden.isCompleted, isTrue,
        reason: 'Clear all must not affect hidden items');
  });
}
