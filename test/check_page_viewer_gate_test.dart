import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sisu_mate/core/di.dart';
import 'package:sisu_mate/data/drift/app_database.dart';
import 'package:sisu_mate/models/models.dart';
import 'package:sisu_mate/services/free_edit_gate.dart';
import 'package:sisu_mate/ui/checklists/check_page_viewer.dart';

/// #125 evidence tests: the detail viewer's Complete action is NOT ungated —
/// it runs through FreeEditGate (access_tiers.md gate #2: 5 free detail
/// completions, then paywall). The P1 report observed a completion that was
/// the documented teaser behaving as designed. These tests pin all three
/// branches at the viewer level, through the real Drift/repository stack.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  const itemId = 'item-gate-1';

  Future<void> seed({int freeEditsUsed = 0}) async {
    await db.into(db.userSettingsTable).insert(
          UserSettingsTableCompanion.insert(
            id: const Value(1),
            freeEditsUsed: Value(freeEditsUsed),
          ),
        );
    await db.into(db.checklistItems).insert(
          ChecklistItemsCompanion.insert(
            supabaseId: const Value(itemId),
            groupSupabaseId: const Value('g1'),
            boatSupabaseId: const Value('b1'),
            title: const Value('Check bilge pump'),
            name: const Value('Check bilge pump'),
          ),
        );
  }

  ChecklistItem viewerItem() => ChecklistItem()
    ..supabaseId = itemId
    ..groupSupabaseId = 'g1'
    ..boatSupabaseId = 'b1'
    ..title = 'Check bilge pump'
    ..name = 'Check bilge pump';

  Future<void> pumpViewer(WidgetTester tester, {required bool isPro}) async {
    final container = ProviderContainer(overrides: [
      appDatabaseProvider.overrideWithValue(db),
      isProProvider.overrideWith((ref) => Stream.value(isPro)),
    ]);
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: CheckPageViewer(
            items: [viewerItem()],
            initialIndex: 0,
            groupName: 'Pre-departure',
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
  }

  Future<void> tapComplete(WidgetTester tester) async {
    final complete = find.text('Complete');
    expect(complete, findsOneWidget,
        reason: 'viewer must show a Complete action');
    await tester.tap(complete);
    await tester.pumpAndSettle();
  }

  Future<bool> dbCompleted() async {
    final row = await (db.select(db.checklistItems)
          ..where((t) => t.supabaseId.equals(itemId)))
        .getSingle();
    return row.isCompleted;
  }

  Future<int> dbFreeEditsUsed() async {
    final row = await db.select(db.userSettingsTable).getSingle();
    return row.freeEditsUsed;
  }

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async => db.close());

  testWidgets(
      '#125 Free with teaser edits left: viewer Complete proceeds and '
      'consumes one free edit (documented access_tiers.md behavior)',
      (tester) async {
    await seed(freeEditsUsed: 0);
    await pumpViewer(tester, isPro: false);

    await tapComplete(tester);

    expect(await dbCompleted(), isTrue,
        reason: 'within the 5-edit teaser, detail completion is allowed');
    expect(await dbFreeEditsUsed(), 1);
  });

  testWidgets(
      '#125 Free with teaser exhausted: viewer Complete is BLOCKED — no '
      'toggleComplete, paywall dialog instead',
      (tester) async {
    await seed(freeEditsUsed: FreeEditGate.freeEditAllowance);
    await pumpViewer(tester, isPro: false);

    await tapComplete(tester);

    expect(await dbCompleted(), isFalse,
        reason: 'past the 5-edit teaser the viewer must hard-lock');
    expect(await dbFreeEditsUsed(), FreeEditGate.freeEditAllowance,
        reason: 'no phantom consumption on a blocked tap');
    expect(find.text('Sisu Mate Pro Required'), findsOneWidget);
  });

  testWidgets(
      '#125 Pro: viewer Complete proceeds without touching the Free counter',
      (tester) async {
    await seed(freeEditsUsed: 0);
    await pumpViewer(tester, isPro: true);

    await tapComplete(tester);

    expect(await dbCompleted(), isTrue);
    expect(await dbFreeEditsUsed(), 0,
        reason: 'Pro is unlimited and must not burn Free teaser edits');
  });
}
