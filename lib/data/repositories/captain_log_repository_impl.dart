import 'dart:convert';
import 'package:drift/drift.dart';
import '../../domain/repositories/captain_log_repository.dart';
import '../../models/models.dart';
import '../drift/app_database.dart';
import '../../services/sync_service.dart';

/// CaptainLogEntry on Drift (S1); sync-participating. `crewOnBoard` and
/// `photos` are JSON text columns.
class CaptainLogRepositoryImpl implements CaptainLogRepository {
  final AppDatabase db;
  final SyncService syncService;

  CaptainLogRepositoryImpl(this.db, this.syncService);

  CaptainLogEntry _toDomain(CaptainLogEntryRow r) => CaptainLogEntry()
    ..id = r.id
    ..supabaseId = r.supabaseId
    ..boatSupabaseId = r.boatSupabaseId
    ..logDate = r.logDate
    ..title = r.title
    ..logTime = r.logTime
    ..positionLat = r.positionLat
    ..positionLng = r.positionLng
    ..weather = r.weather
    ..windSpeedKt = r.windSpeedKt
    ..windDir = r.windDir
    ..crewOnBoard = (jsonDecode(r.crewOnBoard) as List).cast<String>()
    ..notes = r.notes
    ..photos = (jsonDecode(r.photos) as List).cast<String>()
    ..isSynced = r.isSynced
    ..lastModified = r.lastModified;

  CaptainLogEntriesCompanion _toCompanion(CaptainLogEntry l) =>
      CaptainLogEntriesCompanion(
        supabaseId: Value(l.supabaseId),
        boatSupabaseId: Value(l.boatSupabaseId),
        logDate: Value(l.logDate),
        title: Value(l.title),
        logTime: Value(l.logTime),
        positionLat: Value(l.positionLat),
        positionLng: Value(l.positionLng),
        weather: Value(l.weather),
        windSpeedKt: Value(l.windSpeedKt),
        windDir: Value(l.windDir),
        crewOnBoard: Value(jsonEncode(l.crewOnBoard)),
        notes: Value(l.notes),
        photos: Value(jsonEncode(l.photos)),
        isSynced: Value(l.isSynced),
        lastModified: Value(l.lastModified),
      );

  @override
  Stream<List<CaptainLogEntry>> watchLogs() {
    return db.select(db.captainLogEntries).watch().map((rows) {
      final all = rows.map(_toDomain).toList();
      return all..sort((a, b) => b.logDate.compareTo(a.logDate));
    });
  }

  @override
  Future<void> addLog(CaptainLogEntry log) async {
    log.lastModified = DateTime.now().toUtc();
    await db.into(db.captainLogEntries).insert(_toCompanion(log));
    await syncService.queueOutgoingChange('captain_logs', log.toJson());
  }

  @override
  Future<void> updateLog(CaptainLogEntry log) async {
    log.lastModified = DateTime.now().toUtc();
    await (db.update(db.captainLogEntries)
          ..where((t) => t.supabaseId.equals(log.supabaseId)))
        .write(_toCompanion(log));
    await syncService.queueOutgoingChange('captain_logs', log.toJson());
  }

  @override
  Future<void> deleteLog(CaptainLogEntry log) async {
    await (db.delete(db.captainLogEntries)
          ..where((t) => t.supabaseId.equals(log.supabaseId)))
        .go();
    await syncService.queueOutgoingChange(
      'captain_logs',
      {'supabaseId': log.supabaseId},
      isDelete: true,
    );
  }
}
