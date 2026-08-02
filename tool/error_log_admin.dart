// Pure-Dart CLI (run with `dart run`, not `flutter run`) against a *local
// copy* of the app's sisu_mate.sqlite file — see scripts/triage_error_logs.sh
// for how that copy gets there and back.
//
// Raw sqlite3 (not the generated AppDatabase/Drift classes): app_database.dart
// transitively imports path_provider -> flutter/foundation.dart -> dart:ui,
// which plain `dart run` can't resolve (no Flutter engine). Column/table
// names below must stay in sync with the `ErrorLogs` table in
// lib/data/drift/app_database.dart (drift's default snake_case mapping).
// DateTime columns are unix-seconds INTEGER (drift's native default —
// verified empirically against a real drift-written file, not assumed).
//
// Usage:
//   dart run tool/error_log_admin.dart dump-unprocessed <db-path>
//   dart run tool/error_log_admin.dart mark-processed <db-path> <fingerprint> <issue-url>
import 'dart:convert';
import 'dart:io';

import 'package:sqlite3/sqlite3.dart';

void main(List<String> args) {
  if (args.length < 2) {
    stderr.writeln(
        'usage: dart run tool/error_log_admin.dart <dump-unprocessed|mark-processed> <db-path> [fingerprint] [issue-url]');
    exit(2);
  }
  final mode = args[0];
  final dbPath = args[1];
  if (!File(dbPath).existsSync()) {
    stderr.writeln('db not found: $dbPath');
    exit(1);
  }

  final db = sqlite3.open(dbPath);
  try {
    switch (mode) {
      case 'dump-unprocessed':
        _dumpUnprocessed(db);
        break;
      case 'mark-processed':
        if (args.length < 4) {
          stderr.writeln(
              'usage: dart run tool/error_log_admin.dart mark-processed <db-path> <fingerprint> <issue-url>');
          exit(2);
        }
        _markProcessed(db, fingerprint: args[2], issueUrl: args[3]);
        break;
      default:
        stderr.writeln('unknown mode: $mode');
        exit(2);
    }
  } finally {
    db.close();
  }
}

/// One JSON object per line (JSONL) to stdout — easy for the shell script to
/// iterate without parsing a single giant array.
void _dumpUnprocessed(Database db) {
  final rows = db.select(
    'SELECT level, message, stack_trace, source_file, route_hint, '
    'app_version, platform, is_pro, fingerprint, occurrences, created_at, '
    'debug_breadcrumbs '
    'FROM error_logs WHERE processed_at IS NULL '
    'ORDER BY fingerprint, created_at ASC',
  );

  // Group by fingerprint — occurrences already tracks repeats within a run,
  // but a fingerprint can span multiple rows across separate app runs (each
  // run's in-memory dedupe cache starts empty). Merge those here so the
  // triage script files one issue per fingerprint, not one per run.
  final byFingerprint = <String, List<Row>>{};
  for (final r in rows) {
    byFingerprint.putIfAbsent(r['fingerprint'] as String, () => []).add(r);
  }

  for (final entry in byFingerprint.entries) {
    final group = entry.value;
    final totalOccurrences =
        group.fold<int>(0, (sum, r) => sum + (r['occurrences'] as int));
    final first = group.first; // ASC order, so first == earliest
    final last = group.last;
    stdout.writeln(jsonEncode({
      'fingerprint': entry.key,
      'level': last['level'],
      'message': last['message'],
      'stackTrace': last['stack_trace'],
      'sourceFile': last['source_file'],
      'routeHint': last['route_hint'],
      'appVersion': last['app_version'],
      'platform': last['platform'],
      'isPro': (last['is_pro'] as int) != 0,
      'occurrences': totalOccurrences,
      'firstSeen': _secondsToIso(first['created_at'] as int),
      'lastSeen': _secondsToIso(last['created_at'] as int),
      'debugBreadcrumbs': last['debug_breadcrumbs'],
    }));
  }
}

void _markProcessed(
  Database db, {
  required String fingerprint,
  required String issueUrl,
}) {
  final nowSeconds = DateTime.now().toUtc().millisecondsSinceEpoch ~/ 1000;
  db.execute(
    'UPDATE error_logs SET processed_at = ?, issue_url = ? WHERE fingerprint = ?',
    [nowSeconds, issueUrl, fingerprint],
  );
  stdout.writeln('marked ${db.updatedRows} row(s) processed for $fingerprint');
}

String _secondsToIso(int seconds) =>
    DateTime.fromMillisecondsSinceEpoch(seconds * 1000, isUtc: true)
        .toIso8601String();
