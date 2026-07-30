import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sisu_mate/data/drift/app_database.dart';
import 'package:sisu_mate/data/repositories/fuel_log_repository_impl.dart';
import 'package:sisu_mate/models/models.dart';

import '../test_helpers/db_test_helper.dart';

// FuelLogEntry on Drift (S1), sync-participating.
void main() {
  late AppDatabase db;
  late FuelLogRepositoryImpl repo;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = FuelLogRepositoryImpl(db, testSyncService());
  });

  tearDown(() async => db.close());

  group('FuelLogRepositoryImpl (Drift) CRUD', () {
    test('Create: addEntry persists a new entry', () async {
      await repo.addEntry(FuelLogEntry()
        ..supabaseId = 'fuel_1'
        ..type = 'Fuel'
        ..liters = 40
        ..pricePerLiter = 1.85
        ..totalCost = 74);

      final all = await repo.watchEntries().first;
      expect(all, hasLength(1));
      expect(all.single.type, 'Fuel');
      expect(all.single.liters, 40);
      expect(all.single.totalCost, 74);
    });

    test('Read: watchEntries emits entries sorted by date descending', () async {
      await repo.addEntry(FuelLogEntry()
        ..supabaseId = 'fuel_old'
        ..date = DateTime(2026, 1, 1)
        ..liters = 10);
      await repo.addEntry(FuelLogEntry()
        ..supabaseId = 'fuel_new'
        ..date = DateTime(2026, 6, 1)
        ..liters = 20);

      final entries = await repo.watchEntries().first;
      expect(entries.map((e) => e.supabaseId), ['fuel_new', 'fuel_old']);
    });

    test('Update: updateEntry persists field changes', () async {
      final entry = FuelLogEntry()
        ..supabaseId = 'fuel_1'
        ..type = 'Fuel'
        ..liters = 40;
      await repo.addEntry(entry);

      entry
        ..type = 'Water'
        ..liters = 200;
      await repo.updateEntry(entry);

      final all = await repo.watchEntries().first;
      expect(all, hasLength(1));
      expect(all.single.type, 'Water');
      expect(all.single.liters, 200);
    });

    test('Delete: deleteEntry removes it', () async {
      final entry = FuelLogEntry()
        ..supabaseId = 'fuel_1'
        ..liters = 40;
      await repo.addEntry(entry);
      expect(await repo.watchEntries().first, hasLength(1));

      await repo.deleteEntry(entry);
      expect(await repo.watchEntries().first, isEmpty);
    });
  });
}
