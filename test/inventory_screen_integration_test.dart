import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sisu_mate/core/di.dart';
import 'package:sisu_mate/data/drift/app_database.dart';
import 'package:sisu_mate/services/revenuecat_service.dart';
import 'package:sisu_mate/ui/inventory/inventory_screen.dart';

import 'test_helpers/platform_mocks.dart';

/// TEST6 pattern: real InventoryScreen + live provider tree + in-memory Drift.
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

  Future<void> seedItem({
    required String id,
    required String name,
    String? location,
  }) async {
    await db.into(db.inventoryItems).insert(
          InventoryItemsCompanion.insert(
            supabaseId: Value(id),
            name: Value(name),
            location: Value(location),
            quantity: const Value(2),
            unit: const Value('pcs'),
          ),
        );
  }

  Future<void> pumpInventory(WidgetTester tester) async {
    final container = ProviderContainer(overrides: [
      appDatabaseProvider.overrideWithValue(db),
      isProProvider.overrideWith((ref) => Stream.value(true)),
    ]);
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: InventoryScreen()),
      ),
    );
    await tester.pump();
    await tester.pump();
  }

  testWidgets(
      'a row seeded into Drift renders on Inventory through the real stack',
      (tester) async {
    await seedItem(id: 'inv_1', name: 'Spare impeller', location: 'Engine');
    await pumpInventory(tester);

    expect(find.text('Spare impeller'), findsOneWidget);
  });
}
