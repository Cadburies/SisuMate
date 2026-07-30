import '../../models/models.dart';

abstract class FuelLogRepository {
  Stream<List<FuelLogEntry>> watchEntries();
  Future<void> addEntry(FuelLogEntry entry);
  Future<void> updateEntry(FuelLogEntry entry);
  Future<void> deleteEntry(FuelLogEntry entry);
}
