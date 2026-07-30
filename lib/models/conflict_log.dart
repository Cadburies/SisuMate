part of 'models.dart';

/// Concurrent offline edit (T5). Snapshots are domain [toJson] maps as strings.
class ConflictLog {
  ConflictLog();

  int id = 0;
  String table = '';
  String localSupabaseId = '';
  String remoteSupabaseId = '';
  String conflictType = 'concurrent_edit';
  /// `pending` | `keep_local` | `keep_remote`
  String resolution = 'pending';
  String localData = '{}';
  String remoteData = '{}';
  DateTime timestamp = DateTime.now();
  DateTime? resolvedAt;

  bool get isPending => resolution == 'pending';

  factory ConflictLog.fromRow({
    required int id,
    required String targetTable,
    required String localSupabaseId,
    required String remoteSupabaseId,
    required String conflictType,
    required String resolution,
    required String localData,
    required String remoteData,
    required DateTime timestamp,
    DateTime? resolvedAt,
  }) {
    return ConflictLog()
      ..id = id
      ..table = targetTable
      ..localSupabaseId = localSupabaseId
      ..remoteSupabaseId = remoteSupabaseId
      ..conflictType = conflictType
      ..resolution = resolution
      ..localData = localData
      ..remoteData = remoteData
      ..timestamp = timestamp
      ..resolvedAt = resolvedAt;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ConflictLog &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          table == other.table &&
          localSupabaseId == other.localSupabaseId &&
          remoteSupabaseId == other.remoteSupabaseId &&
          conflictType == other.conflictType &&
          resolution == other.resolution &&
          localData == other.localData &&
          remoteData == other.remoteData &&
          timestamp == other.timestamp &&
          resolvedAt == other.resolvedAt;

  @override
  int get hashCode => Object.hashAll([
        id,
        table,
        localSupabaseId,
        remoteSupabaseId,
        conflictType,
        resolution,
        localData,
        remoteData,
        timestamp,
        resolvedAt,
      ]);

  @override
  String toString() => 'ConflictLog(id: $id, table: $table, '
      'localSupabaseId: $localSupabaseId, '
      'remoteSupabaseId: $remoteSupabaseId, conflictType: $conflictType, '
      'resolution: $resolution, timestamp: $timestamp, '
      'resolvedAt: $resolvedAt)';
}
