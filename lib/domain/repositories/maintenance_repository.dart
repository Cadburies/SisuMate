import '../../models/models.dart';

abstract class MaintenanceRepository {
  Stream<List<MaintenanceTask>> watchTasks();
  Future<void> addTask(MaintenanceTask task);
  Future<void> updateTask(MaintenanceTask task);
  Future<void> deleteTask(MaintenanceTask task);
}
