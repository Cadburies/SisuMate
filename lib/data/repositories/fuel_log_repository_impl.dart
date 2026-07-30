import 'package:drift/drift.dart';
import '../../domain/repositories/fuel_log_repository.dart';
import '../../models/models.dart';
import '../drift/app_database.dart';
import '../../services/sync_service.dart';

/// FuelLogEntry on Drift (S1); sync-participating.
class FuelLogRepositoryImpl implements FuelLogRepository {
  final AppDatabase db;
  final SyncService syncService;

  FuelLogRepositoryImpl(this.db, this.syncService);

  FuelLogEntry _toDomain(FuelLogEntryRow r) => FuelLogEntry()
    ..id = r.id
    ..supabaseId = r.supabaseId
    ..boatSupabaseId = r.boatSupabaseId
    ..date = r.date
    ..type = r.type
    ..liters = r.liters
    ..pricePerLiter = r.pricePerLiter
    ..totalCost = r.totalCost
    ..notes = r.notes
    ..isSynced = r.isSynced
    ..lastModified = r.lastModified;

  FuelLogEntriesCompanion _toCompanion(FuelLogEntry e) =>
      FuelLogEntriesCompanion(
        supabaseId: Value(e.supabaseId),
        boatSupabaseId: Value(e.boatSupabaseId),
        date: Value(e.date),
        type: Value(e.type),
        liters: Value(e.liters),
        pricePerLiter: Value(e.pricePerLiter),
        totalCost: Value(e.totalCost),
        notes: Value(e.notes),
        isSynced: Value(e.isSynced),
        lastModified: Value(e.lastModified),
      );

  @override
  Stream<List<FuelLogEntry>> watchEntries() {
    return db.select(db.fuelLogEntries).watch().map((rows) {
      final all = rows.map(_toDomain).toList();
      return all..sort((a, b) => b.date.compareTo(a.date));
    });
  }

  @override
  Future<void> addEntry(FuelLogEntry entry) async {
    entry.lastModified = DateTime.now().toUtc();
    await db.into(db.fuelLogEntries).insert(_toCompanion(entry));
    await syncService.queueOutgoingChange('fuel_logs', entry.toJson());
  }

  @override
  Future<void> updateEntry(FuelLogEntry entry) async {
    entry.lastModified = DateTime.now().toUtc();
    await (db.update(db.fuelLogEntries)
          ..where((t) => t.supabaseId.equals(entry.supabaseId)))
        .write(_toCompanion(entry));
    await syncService.queueOutgoingChange('fuel_logs', entry.toJson());
  }

  @override
  Future<void> deleteEntry(FuelLogEntry entry) async {
    await (db.delete(db.fuelLogEntries)
          ..where((t) => t.supabaseId.equals(entry.supabaseId)))
        .go();
    await syncService.queueOutgoingChange(
      'fuel_logs',
      {'supabaseId': entry.supabaseId},
      isDelete: true,
    );
  }
}
