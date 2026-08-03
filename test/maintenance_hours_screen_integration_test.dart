import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sisu_mate/core/di.dart';
import 'package:sisu_mate/data/drift/app_database.dart';
import 'package:sisu_mate/services/revenuecat_service.dart';
import 'package:sisu_mate/ui/maintenance/maintenance_hours_screen.dart';

import 'test_helpers/platform_mocks.dart';

/// TEST6 pattern: real MaintenanceHoursScreen + live provider tree + in-
/// memory Drift. #216: this is the screen that closes the "no UI lets a
/// user log engine hours / a last-serviced date against a MaintenanceTask"
/// gap the live Maintenance screen (ChecklistItem-backed) never covered.
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

  Future<void> seedTask({
    required String id,
    required String description,
    int? intervalMonths,
    DateTime? lastDoneDate,
  }) async {
    await db.into(db.maintenanceTasks).insert(
          MaintenanceTasksCompanion.insert(
            supabaseId: Value(id),
            description: Value(description),
            intervalMonths: Value(intervalMonths),
            lastDoneDate: Value(lastDoneDate),
          ),
        );
  }

  Future<ProviderContainer> pumpScreen(WidgetTester tester) async {
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

  testWidgets(
      'a maintenance task seeded into Drift renders through the real stack',
      (tester) async {
    await seedTask(id: 'maint_1', description: 'Replace impeller');
    await pumpScreen(tester);

    expect(find.text('Replace impeller'), findsOneWidget);
  });

  testWidgets('an overdue calendar-interval task shows an attention line',
      (tester) async {
    await seedTask(
      id: 'maint_overdue',
      description: 'Service winch',
      intervalMonths: 6,
      lastDoneDate: DateTime.utc(2020, 1, 1),
    );
    await pumpScreen(tester);

    expect(find.textContaining('overdue by'), findsOneWidget);
  });

  testWidgets('adding a task through the FAB dialog persists it to Drift',
      (tester) async {
    await pumpScreen(tester);
    expect(find.text('No maintenance tasks logged yet — add one '
        'with engine hours or a service interval.'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Description'), 'Change oil');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(find.text('Change oil'), findsOneWidget);

    final rows = await db.select(db.maintenanceTasks).get();
    expect(rows, hasLength(1));
    expect(rows.single.description, 'Change oil');
  });
}
