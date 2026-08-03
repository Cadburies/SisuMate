import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sisu_mate/core/di.dart';
import 'package:sisu_mate/data/drift/app_database.dart';
import 'package:sisu_mate/models/models.dart';
import 'package:sisu_mate/services/revenuecat_service.dart';
import 'package:sisu_mate/ui/logbook/history_pattern_dialog.dart';

import 'test_helpers/platform_mocks.dart';

CaptainLogEntry _log({required DateTime date, String? notes}) =>
    CaptainLogEntry()
      ..supabaseId = 'log_${date.millisecondsSinceEpoch}'
      ..logDate = date
      ..notes = notes;

MaintenanceTask _task({required DateTime modified, String? notes}) =>
    MaintenanceTask()
      ..supabaseId = 'maint_${modified.millisecondsSinceEpoch}'
      ..description = 'Task'
      ..notes = notes
      ..lastModified = modified;

/// #218 / #208: the "not enough history" gate must never reach the LLM
/// (mustn't burn BYOK tokens on a query with nothing to find a pattern in),
/// and the no-key/offline states must match #18's established pattern.
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

  Future<void> pumpDialog(
    WidgetTester tester, {
    required List<CaptainLogEntry> logEntries,
    required List<MaintenanceTask> maintenanceTasks,
  }) async {
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

    final container = ProviderContainer(overrides: [
      appDatabaseProvider.overrideWithValue(db),
      isProProvider.overrideWith((ref) => Stream.value(true)),
    ]);
    addTearDown(container.dispose);

    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        home: Scaffold(
          body: HistoryPatternDialog(
            logEntries: logEntries,
            maintenanceTasks: maintenanceTasks,
          ),
        ),
      ),
    ));
    await tester.pump();
    await tester.pump();
  }

  testWidgets(
      'fewer than 3 qualifying notes shows "not enough history" instead of '
      'querying the LLM', (tester) async {
    await pumpDialog(tester, logEntries: [
      _log(date: DateTime.now(), notes: 'all good'),
    ], maintenanceTasks: []);

    expect(find.textContaining('Not enough log or maintenance notes yet'),
        findsOneWidget);
    expect(find.textContaining('No AI API key is configured'), findsNothing);
  });

  testWidgets('entries with empty/null notes do not count toward the '
      'minimum', (tester) async {
    await pumpDialog(tester, logEntries: [
      _log(date: DateTime.now(), notes: 'vibration at 2400 RPM'),
      _log(date: DateTime.now(), notes: ''),
      _log(date: DateTime.now(), notes: null),
    ], maintenanceTasks: []);

    expect(find.textContaining('Not enough log or maintenance notes yet'),
        findsOneWidget);
  });

  testWidgets('entries older than the 180-day lookback do not count toward '
      'the minimum', (tester) async {
    final old = DateTime.now().subtract(const Duration(days: 400));
    await pumpDialog(tester, logEntries: [
      _log(date: old, notes: 'note 1'),
      _log(date: old, notes: 'note 2'),
      _log(date: old, notes: 'note 3'),
    ], maintenanceTasks: []);

    expect(find.textContaining('Not enough log or maintenance notes yet'),
        findsOneWidget);
  });

  testWidgets('3+ qualifying notes across both log and maintenance sources '
      'trigger the query and show the no-key fallback', (tester) async {
    final now = DateTime.now();
    await pumpDialog(tester, logEntries: [
      _log(date: now, notes: 'vibration at 2400 RPM'),
      _log(date: now.subtract(const Duration(days: 10)),
          notes: 'vibration again'),
    ], maintenanceTasks: [
      _task(modified: now, notes: 'checked sensor, reset'),
    ]);

    expect(find.textContaining('No AI API key is configured'), findsOneWidget);
    expect(find.text('Go to Settings'), findsOneWidget);
  });
}
