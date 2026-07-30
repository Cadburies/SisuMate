import 'package:drift/drift.dart';
import '../../domain/repositories/maintenance_repository.dart';
import '../../models/models.dart';
import '../drift/app_database.dart';
import '../../services/sync_service.dart';

/// MaintenanceTask on Drift (S1); sync-participating.
class MaintenanceRepositoryImpl implements MaintenanceRepository {
  final AppDatabase db;
  final SyncService syncService;

  MaintenanceRepositoryImpl(this.db, this.syncService);

  MaintenanceTask _toDomain(MaintenanceTaskRow r) => MaintenanceTask()
    ..id = r.id
    ..supabaseId = r.supabaseId
    ..boatSupabaseId = r.boatSupabaseId
    ..description = r.description
    ..intervalHours = r.intervalHours
    ..intervalMonths = r.intervalMonths
    ..lastDoneHours = r.lastDoneHours
    ..lastDoneDate = r.lastDoneDate
    ..doneBy = r.doneBy
    ..notes = r.notes
    ..isHidden = r.isHidden
    ..isSynced = r.isSynced
    ..lastModified = r.lastModified;

  MaintenanceTasksCompanion _toCompanion(MaintenanceTask t) =>
      MaintenanceTasksCompanion(
        supabaseId: Value(t.supabaseId),
        boatSupabaseId: Value(t.boatSupabaseId),
        description: Value(t.description),
        intervalHours: Value(t.intervalHours),
        intervalMonths: Value(t.intervalMonths),
        lastDoneHours: Value(t.lastDoneHours),
        lastDoneDate: Value(t.lastDoneDate),
        doneBy: Value(t.doneBy),
        notes: Value(t.notes),
        isHidden: Value(t.isHidden),
        isSynced: Value(t.isSynced),
        lastModified: Value(t.lastModified),
      );

  @override
  Stream<List<MaintenanceTask>> watchTasks() {
    return db.select(db.maintenanceTasks).watch().map(
        (rows) => rows.map(_toDomain).where((t) => !t.isHidden).toList());
  }

  @override
  Future<void> addTask(MaintenanceTask task) async {
    task.lastModified = DateTime.now().toUtc();
    await db.into(db.maintenanceTasks).insert(_toCompanion(task));
    await syncService.queueOutgoingChange('maintenance_tasks', task.toJson());
  }

  @override
  Future<void> updateTask(MaintenanceTask task) async {
    task.lastModified = DateTime.now().toUtc();
    await (db.update(db.maintenanceTasks)
          ..where((t) => t.supabaseId.equals(task.supabaseId)))
        .write(_toCompanion(task));
    await syncService.queueOutgoingChange('maintenance_tasks', task.toJson());
  }

  @override
  Future<void> deleteTask(MaintenanceTask task) async {
    await (db.delete(db.maintenanceTasks)
          ..where((t) => t.supabaseId.equals(task.supabaseId)))
        .go();
    await syncService.queueOutgoingChange(
      'maintenance_tasks',
      {'supabaseId': task.supabaseId},
      isDelete: true,
    );
  }
}
