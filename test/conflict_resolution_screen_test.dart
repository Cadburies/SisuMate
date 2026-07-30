import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sisu_mate/core/di.dart';
import 'package:sisu_mate/models/models.dart';
import 'package:sisu_mate/ui/conflicts/conflict_resolution_screen.dart';

/// Widget-level coverage for the Sync Conflicts screen (TEST1b) — the UI half
/// of the T5 conflict-resolution feature; `conflict_resolution_test.dart`
/// already covers `resolveConflict` itself at the service level.
///
/// `pendingConflictsProvider` is overridden directly with a canned stream
/// rather than a real `appDatabaseProvider` + `SyncService`. The latter
/// deadlocks `testWidgets`'s fake clock the same way `syncOutboxCountProvider`
/// does in `item_detail_shell_test.dart` — a SyncService constructed inside a
/// widget test's zone never finishes its real async init, and the test hangs
/// for the full ~20 min default timeout instead of failing fast.
void main() {
  ConflictLog conflict({
    String table = 'shopping_items',
    String localName = 'SyncTest-Offline',
    String remoteName = 'SyncTest-Online',
  }) {
    return ConflictLog()
      ..id = 1
      ..table = table
      ..localSupabaseId = 'item-1'
      ..remoteSupabaseId = 'item-1'
      ..localData = jsonEncode({
        'name': localName,
        'lastModified': '2026-01-01T00:00:00.000Z',
      })
      ..remoteData = jsonEncode({
        'name': remoteName,
        'lastModified': '2026-01-02T00:00:00.000Z',
      });
  }

  Future<void> pumpScreen(
    WidgetTester tester,
    List<ConflictLog> conflicts,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          pendingConflictsProvider.overrideWith(
            (ref) => Stream.value(conflicts),
          ),
        ],
        child: const MaterialApp(home: ConflictResolutionScreen()),
      ),
    );
    await tester.pump();
    await tester.pump();
  }

  testWidgets('empty state shown when there are no pending conflicts',
      (tester) async {
    await pumpScreen(tester, []);

    expect(find.text('Sync Conflicts'), findsOneWidget);
    expect(find.textContaining('No pending conflicts'), findsOneWidget);
  });

  testWidgets(
      'a pending conflict renders both sides with table label + resolve buttons',
      (tester) async {
    await pumpScreen(tester, [conflict()]);

    expect(find.text('Shopping item'), findsOneWidget);
    expect(find.textContaining('SyncTest-Offline'), findsOneWidget);
    expect(find.textContaining('SyncTest-Online'), findsOneWidget);
    expect(find.text('Keep mine'), findsOneWidget);
    expect(find.text('Keep cloud'), findsOneWidget);
  });

  testWidgets('table label maps to a friendly name per synced table',
      (tester) async {
    await pumpScreen(tester, [
      conflict(table: 'captain_logs'),
    ]);

    expect(find.text("Captain's log"), findsOneWidget);
  });

  testWidgets('multiple pending conflicts each render their own card',
      (tester) async {
    await pumpScreen(tester, [
      conflict(table: 'shopping_items', localName: 'A-mine', remoteName: 'A-cloud'),
      conflict(table: 'maintenance_tasks', localName: 'B-mine', remoteName: 'B-cloud'),
    ]);

    expect(find.text('Shopping item'), findsOneWidget);
    expect(find.text('Maintenance task'), findsOneWidget);
    expect(find.text('Keep mine'), findsNWidgets(2));
    expect(find.text('Keep cloud'), findsNWidgets(2));
  });
}
