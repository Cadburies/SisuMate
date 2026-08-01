part of 'models.dart';

/// App error/exception/warning telemetry (#121). Local-only — never synced.
class ErrorLogEntry {
  ErrorLogEntry();

  int id = 0;
  DateTime createdAt = DateTime.now();
  /// `warning` | `error` | `exception`
  String level = 'error';
  String message = '';
  String? stackTrace;
  String? sourceFile;
  String? routeHint;
  String appVersion = '';
  String platform = '';
  bool isPro = false;
  String fingerprint = '';
  int occurrences = 1;
  DateTime? processedAt;
  String? issueUrl;

  bool get isProcessed => processedAt != null;

  factory ErrorLogEntry.fromRow({
    required int id,
    required DateTime createdAt,
    required String level,
    required String message,
    String? stackTrace,
    String? sourceFile,
    String? routeHint,
    required String appVersion,
    required String platform,
    required bool isPro,
    required String fingerprint,
    required int occurrences,
    DateTime? processedAt,
    String? issueUrl,
  }) {
    return ErrorLogEntry()
      ..id = id
      ..createdAt = createdAt
      ..level = level
      ..message = message
      ..stackTrace = stackTrace
      ..sourceFile = sourceFile
      ..routeHint = routeHint
      ..appVersion = appVersion
      ..platform = platform
      ..isPro = isPro
      ..fingerprint = fingerprint
      ..occurrences = occurrences
      ..processedAt = processedAt
      ..issueUrl = issueUrl;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ErrorLogEntry &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          createdAt == other.createdAt &&
          level == other.level &&
          message == other.message &&
          stackTrace == other.stackTrace &&
          sourceFile == other.sourceFile &&
          routeHint == other.routeHint &&
          appVersion == other.appVersion &&
          platform == other.platform &&
          isPro == other.isPro &&
          fingerprint == other.fingerprint &&
          occurrences == other.occurrences &&
          processedAt == other.processedAt &&
          issueUrl == other.issueUrl;

  @override
  int get hashCode => Object.hashAll([
        id,
        createdAt,
        level,
        message,
        stackTrace,
        sourceFile,
        routeHint,
        appVersion,
        platform,
        isPro,
        fingerprint,
        occurrences,
        processedAt,
        issueUrl,
      ]);

  @override
  String toString() => 'ErrorLogEntry(id: $id, level: $level, '
      'sourceFile: $sourceFile, fingerprint: $fingerprint, '
      'occurrences: $occurrences, processedAt: $processedAt)';
}
