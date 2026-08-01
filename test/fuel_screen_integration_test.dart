import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sisu_mate/core/di.dart';
import 'package:sisu_mate/data/drift/app_database.dart';
import 'package:sisu_mate/services/revenuecat_service.dart';
import 'package:sisu_mate/ui/fuel/fuel_screen.dart';

import 'test_helpers/platform_mocks.dart';

/// TEST6 pattern: real FuelScreen + live provider tree + in-memory Drift.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late AppDatabase db;

  setUp(() {
    mockConnectivityChannel();
    db = AppDatabase.forTesting(NativeDatabase.memory());
    RevenueCatService.debugProOverrideForTests = true;
  });

  tearDown(() async {
    RevenueCatService.debugProOverrideForTests = null;
    await db.close();
  });

  Future<void> seedEntry({
    required String id,
    required String notes,
    String type = 'Fuel',
  }) async {
    await db.into(db.fuelLogEntries).insert(
          FuelLogEntriesCompanion.insert(
            supabaseId: Value(id),
            type: Value(type),
            liters: const Value(40),
            notes: Value(notes),
            date: Value(DateTime.utc(2026, 7, 1)),
          ),
        );
  }

  Future<void> pumpFuel(WidgetTester tester) async {
    final container = ProviderContainer(overrides: [
      appDatabaseProvider.overrideWithValue(db),
      isProProvider.overrideWith((ref) => Stream.value(true)),
    ]);
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: FuelScreen()),
      ),
    );
    await tester.pump();
    await tester.pump();
  }

  testWidgets(
      'a fuel log seeded into Drift renders on Fuel through the real stack',
      (tester) async {
    await seedEntry(id: 'fuel_1', notes: 'Harbor fill-up');
    await pumpFuel(tester);

    expect(find.text('Harbor fill-up'), findsOneWidget);
  });
}
