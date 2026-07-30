part of 'models.dart';

// Domain data class. Persisted via the Drift `SyncOutboxItems` table in
// SyncService.
class SyncOutbox {
  int id = 0;
  String tableName = '';
  String recordId = '';
  String operation = 'create';
  String data = '';
  int priority = 0;
  bool isDelete = false;
  String status = 'pending';
  int retryCount = 0;
  DateTime createdAt = DateTime.now();
  DateTime? lastAttemptAt;
  String? lastError;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SyncOutbox &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          tableName == other.tableName &&
          recordId == other.recordId &&
          operation == other.operation &&
          data == other.data &&
          priority == other.priority &&
          isDelete == other.isDelete &&
          status == other.status &&
          retryCount == other.retryCount &&
          createdAt == other.createdAt &&
          lastAttemptAt == other.lastAttemptAt &&
          lastError == other.lastError;

  @override
  int get hashCode => Object.hashAll([
        id,
        tableName,
        recordId,
        operation,
        data,
        priority,
        isDelete,
        status,
        retryCount,
        createdAt,
        lastAttemptAt,
        lastError,
      ]);

  @override
  String toString() => 'SyncOutbox(id: $id, tableName: $tableName, '
      'recordId: $recordId, operation: $operation, priority: $priority, '
      'isDelete: $isDelete, status: $status, retryCount: $retryCount, '
      'createdAt: $createdAt, lastAttemptAt: $lastAttemptAt, '
      'lastError: $lastError)';
}