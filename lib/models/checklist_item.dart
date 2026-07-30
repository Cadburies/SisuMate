part of 'models.dart';

class ChecklistItem {
  int id = 0;
  String? assetName;
  String boatSupabaseId = '';
  DateTime? completedAt;
  List<String> completionHistory = [];
  DateTime createdAt = DateTime.now();
  String? description;
  String groupSupabaseId = '';
  bool isBundled = false;
  bool isCompleted = false;
  bool isHidden = false;
  bool isPermanentlyDeleted = false;
  bool isSynced = false;
  DateTime lastModified = DateTime.now().toUtc();
  String name = '';
  String title = '';
  String? notes;
  String? photoUrl;
  String? userPhotoUrl;
  String? userPhotoPath;
  int sortOrder = 0;
  String supabaseId = '';

  ChecklistItem();

  factory ChecklistItem.fromJson(Map<String, dynamic> json) {
    return ChecklistItem()
      ..assetName = json['assetName']
      ..boatSupabaseId = json['boatSupabaseId'] ?? ''
      ..completedAt = json['completedAt'] != null ? DateTime.parse(json['completedAt']) : null
      ..completionHistory = List<String>.from(json['completionHistory'] ?? [])
      ..createdAt = DateTime.parse(json['createdAt'])
      ..description = json['description']
      ..groupSupabaseId = json['groupSupabaseId'] ?? ''
      ..isBundled = json['isBundled'] ?? false
      ..isCompleted = json['isCompleted'] ?? false
      ..isHidden = json['isHidden'] ?? false
      ..isPermanentlyDeleted = json['isPermanentlyDeleted'] ?? false
      ..isSynced = json['isSynced'] ?? false
      ..lastModified = DateTime.parse(json['lastModified'])
      ..name = json['name'] ?? ''
      ..title = json['title'] ?? ''
      ..notes = json['notes']
      ..photoUrl = json['photoUrl']
      ..userPhotoUrl = json['userPhotoUrl']
      ..userPhotoPath = json['userPhotoPath']
      ..sortOrder = json['sortOrder'] ?? 0
      ..supabaseId = json['supabaseId'] ?? '';
  }

  Map<String, dynamic> toJson() => {
    'supabaseId': supabaseId,
    'boatSupabaseId': boatSupabaseId,
    'groupSupabaseId': groupSupabaseId,
    'title': title,
    'name': name,
    'description': description,
    'assetName': assetName,
    'photoUrl': photoUrl,
    'userPhotoUrl': userPhotoUrl,
    'userPhotoPath': userPhotoPath,
    'notes': notes,
    'isCompleted': isCompleted,
    'completedAt': completedAt?.toIso8601String(),
    'completionHistory': completionHistory,
    'isBundled': isBundled,
    'isHidden': isHidden,
    'isPermanentlyDeleted': isPermanentlyDeleted,
    'isSynced': isSynced,
    'createdAt': createdAt.toIso8601String(),
    'lastModified': lastModified.toIso8601String(),
    'sortOrder': sortOrder,
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChecklistItem &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          assetName == other.assetName &&
          boatSupabaseId == other.boatSupabaseId &&
          completedAt == other.completedAt &&
          listEquals(completionHistory, other.completionHistory) &&
          createdAt == other.createdAt &&
          description == other.description &&
          groupSupabaseId == other.groupSupabaseId &&
          isBundled == other.isBundled &&
          isCompleted == other.isCompleted &&
          isHidden == other.isHidden &&
          isPermanentlyDeleted == other.isPermanentlyDeleted &&
          isSynced == other.isSynced &&
          lastModified == other.lastModified &&
          name == other.name &&
          title == other.title &&
          notes == other.notes &&
          photoUrl == other.photoUrl &&
          userPhotoUrl == other.userPhotoUrl &&
          userPhotoPath == other.userPhotoPath &&
          sortOrder == other.sortOrder &&
          supabaseId == other.supabaseId;

  @override
  int get hashCode => Object.hashAll([
        id,
        assetName,
        boatSupabaseId,
        completedAt,
        Object.hashAll(completionHistory),
        createdAt,
        description,
        groupSupabaseId,
        isBundled,
        isCompleted,
        isHidden,
        isPermanentlyDeleted,
        isSynced,
        lastModified,
        name,
        title,
        notes,
        photoUrl,
        userPhotoUrl,
        userPhotoPath,
        sortOrder,
        supabaseId,
      ]);

  @override
  String toString() => 'ChecklistItem(id: $id, supabaseId: $supabaseId, '
      'groupSupabaseId: $groupSupabaseId, boatSupabaseId: $boatSupabaseId, '
      'title: $title, name: $name, description: $description, '
      'assetName: $assetName, photoUrl: $photoUrl, '
      'userPhotoUrl: $userPhotoUrl, userPhotoPath: $userPhotoPath, '
      'notes: $notes, isCompleted: $isCompleted, completedAt: $completedAt, '
      'completionHistory: $completionHistory, isBundled: $isBundled, '
      'isHidden: $isHidden, isPermanentlyDeleted: $isPermanentlyDeleted, '
      'isSynced: $isSynced, createdAt: $createdAt, '
      'lastModified: $lastModified, sortOrder: $sortOrder)';
}
