import '../../models/models.dart';

abstract class ErrorLogRepository {
  /// Inserts a new row (occurrences = 1) and returns its id.
  Future<int> insert(ErrorLogEntry entry);

  /// Bumps `occurrences` by 1 on an existing row.
  Future<void> incrementOccurrences(int id);

  /// Most recent row for [fingerprint] within this app run, if any — used to
  /// dedupe repeat errors into a single row instead of spamming new ones.
  Future<ErrorLogEntry?> findByFingerprint(String fingerprint);

  /// Rows not yet claimed by the triage automation, oldest first.
  Future<List<ErrorLogEntry>> getUnprocessed();

  Future<void> markProcessed(String fingerprint, {required String issueUrl});
}
