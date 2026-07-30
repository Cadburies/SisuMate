part of 'models.dart';

class ChecklistGroup {
  ChecklistGroup();

  int id = 0;
  String appType = '';
  String boatSupabaseId = '';
  String? description;
  String iconName = '';
  bool isBought = false;
  bool isBundled = false;
  bool isExpanded = false;
  bool isHidden = false;
  bool isSynced = false;
  DateTime lastModified = DateTime.now().toUtc();
  double? lastPurchasePrice;
  String notes = '';
  String origin = '';
  int sortOrder = 0;
  String supabaseId = '';
  String title = '';
  // S5: set only when origin == 'community' — which community_templates row
  // (and the version at import time) this group came from. Drives "update
  // available" detection on the Community screen.
  String? communityTemplateId;
  int? communityTemplateVersion;

  factory ChecklistGroup.fromJson(Map<String, dynamic> json) {
    return ChecklistGroup()
      ..appType = json['appType'] ?? ''
      ..boatSupabaseId = json['boatSupabaseId'] ?? ''
      ..description = json['description']
      ..iconName = json['iconName'] ?? ''
      ..isBought = json['isBought'] ?? false
      ..isBundled = json['isBundled'] ?? false
      ..isExpanded = json['isExpanded'] ?? false
      ..isHidden = json['isHidden'] ?? false
      ..isSynced = json['isSynced'] ?? false
      ..lastModified = DateTime.parse(json['lastModified'])
      ..lastPurchasePrice = json['lastPurchasePrice']?.toDouble()
      ..notes = json['notes'] ?? ''
      ..origin = json['origin'] ?? ''
      ..sortOrder = json['sortOrder'] ?? 0
      ..supabaseId = json['supabaseId'] ?? ''
      ..title = json['title'] ?? ''
      ..communityTemplateId = json['communityTemplateId']
      ..communityTemplateVersion = json['communityTemplateVersion'];
  }

  Map<String, dynamic> toJson() => {
    'supabaseId': supabaseId,
    'boatSupabaseId': boatSupabaseId,
    'appType': appType,
    'title': title,
    'description': description,
    'iconName': iconName,
    'isBought': isBought,
    'isBundled': isBundled,
    'isExpanded': isExpanded,
    'isHidden': isHidden,
    'isSynced': isSynced,
    'lastModified': lastModified.toIso8601String(),
    'lastPurchasePrice': lastPurchasePrice,
    'notes': notes,
    'origin': origin,
    'sortOrder': sortOrder,
    'communityTemplateId': communityTemplateId,
    'communityTemplateVersion': communityTemplateVersion,
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChecklistGroup &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          appType == other.appType &&
          boatSupabaseId == other.boatSupabaseId &&
          description == other.description &&
          iconName == other.iconName &&
          isBought == other.isBought &&
          isBundled == other.isBundled &&
          isExpanded == other.isExpanded &&
          isHidden == other.isHidden &&
          isSynced == other.isSynced &&
          lastModified == other.lastModified &&
          lastPurchasePrice == other.lastPurchasePrice &&
          notes == other.notes &&
          origin == other.origin &&
          sortOrder == other.sortOrder &&
          supabaseId == other.supabaseId &&
          title == other.title &&
          communityTemplateId == other.communityTemplateId &&
          communityTemplateVersion == other.communityTemplateVersion;

  @override
  int get hashCode => Object.hashAll([
        id,
        appType,
        boatSupabaseId,
        description,
        iconName,
        isBought,
        isBundled,
        isExpanded,
        isHidden,
        isSynced,
        lastModified,
        lastPurchasePrice,
        notes,
        origin,
        sortOrder,
        supabaseId,
        title,
        communityTemplateId,
        communityTemplateVersion,
      ]);

  @override
  String toString() => 'ChecklistGroup(id: $id, supabaseId: $supabaseId, '
      'title: $title, appType: $appType, boatSupabaseId: $boatSupabaseId, '
      'description: $description, iconName: $iconName, '
      'isBought: $isBought, isBundled: $isBundled, isExpanded: $isExpanded, '
      'isHidden: $isHidden, isSynced: $isSynced, '
      'lastModified: $lastModified, lastPurchasePrice: $lastPurchasePrice, '
      'notes: $notes, origin: $origin, sortOrder: $sortOrder, '
      'communityTemplateId: $communityTemplateId, '
      'communityTemplateVersion: $communityTemplateVersion)';
}
