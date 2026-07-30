part of 'models.dart';

class MaintenanceTask {
  MaintenanceTask();

  int id = 0;
  String supabaseId = '';
  String boatSupabaseId = '';
  String description = '';
  int? intervalHours;
  int? intervalMonths;
  int? lastDoneHours;
  DateTime? lastDoneDate;
  String? doneBy;
  String? notes;
  bool isHidden = false;
  bool isSynced = false;
  DateTime lastModified = DateTime.now().toUtc();

  factory MaintenanceTask.fromJson(Map<String, dynamic> json) {
    return MaintenanceTask()
      ..supabaseId = json['supabaseId'] ?? ''
      ..boatSupabaseId = json['boatSupabaseId'] ?? ''
      ..description = json['description'] ?? ''
      ..intervalHours = json['intervalHours']
      ..intervalMonths = json['intervalMonths']
      ..lastDoneHours = json['lastDoneHours']
      ..lastDoneDate = json['lastDoneDate'] != null ? DateTime.parse(json['lastDoneDate']) : null
      ..doneBy = json['doneBy']
      ..notes = json['notes']
      ..isHidden = json['isHidden'] ?? false
      ..isSynced = json['isSynced'] ?? false
      ..lastModified = DateTime.parse(json['lastModified']);
  }

  Map<String, dynamic> toJson() => {
    'supabaseId': supabaseId,
    'boatSupabaseId': boatSupabaseId,
    'description': description,
    'intervalHours': intervalHours,
    'intervalMonths': intervalMonths,
    'lastDoneHours': lastDoneHours,
    'lastDoneDate': lastDoneDate?.toIso8601String(),
    'doneBy': doneBy,
    'notes': notes,
    'isHidden': isHidden,
    'isSynced': isSynced,
    'lastModified': lastModified.toIso8601String(),
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MaintenanceTask &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          supabaseId == other.supabaseId &&
          boatSupabaseId == other.boatSupabaseId &&
          description == other.description &&
          intervalHours == other.intervalHours &&
          intervalMonths == other.intervalMonths &&
          lastDoneHours == other.lastDoneHours &&
          lastDoneDate == other.lastDoneDate &&
          doneBy == other.doneBy &&
          notes == other.notes &&
          isHidden == other.isHidden &&
          isSynced == other.isSynced &&
          lastModified == other.lastModified;

  @override
  int get hashCode => Object.hashAll([
        id,
        supabaseId,
        boatSupabaseId,
        description,
        intervalHours,
        intervalMonths,
        lastDoneHours,
        lastDoneDate,
        doneBy,
        notes,
        isHidden,
        isSynced,
        lastModified,
      ]);

  @override
  String toString() => 'MaintenanceTask(id: $id, supabaseId: $supabaseId, '
      'boatSupabaseId: $boatSupabaseId, description: $description, '
      'intervalHours: $intervalHours, intervalMonths: $intervalMonths, '
      'lastDoneHours: $lastDoneHours, lastDoneDate: $lastDoneDate, '
      'doneBy: $doneBy, notes: $notes, isHidden: $isHidden, '
      'isSynced: $isSynced, lastModified: $lastModified)';
}