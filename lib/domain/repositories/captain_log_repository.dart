import '../../models/models.dart';

abstract class CaptainLogRepository {
  Stream<List<CaptainLogEntry>> watchLogs();
  Future<void> addLog(CaptainLogEntry log);
  Future<void> updateLog(CaptainLogEntry log);
  Future<void> deleteLog(CaptainLogEntry log);
}
