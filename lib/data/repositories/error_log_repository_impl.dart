import 'package:drift/drift.dart';
import '../../models/models.dart';
import '../drift/app_database.dart';
import '../../domain/repositories/error_log_repository.dart';

class ErrorLogRepositoryImpl implements ErrorLogRepository {
  final AppDatabase _db;
  ErrorLogRepositoryImpl(this._db);

  ErrorLogEntry _toDomain(ErrorLogRow r) => ErrorLogEntry.fromRow(
        id: r.id,
        createdAt: r.createdAt,
        level: r.level,
        message: r.message,
        stackTrace: r.stackTrace,
        sourceFile: r.sourceFile,
        routeHint: r.routeHint,
        appVersion: r.appVersion,
        platform: r.platform,
        isPro: r.isPro,
        fingerprint: r.fingerprint,
        occurrences: r.occurrences,
        processedAt: r.processedAt,
        issueUrl: r.issueUrl,
        debugBreadcrumbs: r.debugBreadcrumbs,
      );

  @override
  Future<int> insert(ErrorLogEntry entry) {
    return _db.into(_db.errorLogs).insert(ErrorLogsCompanion.insert(
          createdAt: Value(entry.createdAt),
          level: Value(entry.level),
          message: Value(entry.message),
          stackTrace: Value(entry.stackTrace),
          sourceFile: Value(entry.sourceFile),
          routeHint: Value(entry.routeHint),
          appVersion: Value(entry.appVersion),
          platform: Value(entry.platform),
          isPro: Value(entry.isPro),
          fingerprint: Value(entry.fingerprint),
          occurrences: Value(entry.occurrences),
          debugBreadcrumbs: Value(entry.debugBreadcrumbs),
        ));
  }

  @override
  Future<void> incrementOccurrences(int id) async {
    final row = await (_db.select(_db.errorLogs)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
    if (row == null) return;
    await (_db.update(_db.errorLogs)..where((t) => t.id.equals(id)))
        .write(ErrorLogsCompanion(occurrences: Value(row.occurrences + 1)));
  }

  @override
  Future<ErrorLogEntry?> findByFingerprint(String fingerprint) async {
    final row = await (_db.select(_db.errorLogs)
          ..where((t) => t.fingerprint.equals(fingerprint))
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)])
          ..limit(1))
        .getSingleOrNull();
    return row == null ? null : _toDomain(row);
  }

  @override
  Future<List<ErrorLogEntry>> getUnprocessed() async {
    final rows = await (_db.select(_db.errorLogs)
          ..where((t) => t.processedAt.isNull())
          ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
        .get();
    return rows.map(_toDomain).toList();
  }

  @override
  Future<void> markProcessed(String fingerprint, {required String issueUrl}) async {
    await (_db.update(_db.errorLogs)
          ..where((t) => t.fingerprint.equals(fingerprint)))
        .write(ErrorLogsCompanion(
      processedAt: Value(DateTime.now()),
      issueUrl: Value(issueUrl),
    ));
  }
}
