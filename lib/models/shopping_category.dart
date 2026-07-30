part of 'models.dart';

class ShoppingCategory {
  ShoppingCategory();

  int id = 0;
  String boatSupabaseId = '';
  String name = '';
  int sortOrder = 0;
  bool isSynced = false;
  DateTime lastModified = DateTime.now().toUtc();
  String supabaseId = '';

  factory ShoppingCategory.fromJson(Map<String, dynamic> json) {
    return ShoppingCategory()
      ..supabaseId = json['supabaseId'] ?? ''
      ..boatSupabaseId = json['boatSupabaseId'] ?? ''
      ..name = json['name'] ?? ''
      ..sortOrder = json['sortOrder'] ?? 0
      ..isSynced = json['isSynced'] ?? false
      ..lastModified = DateTime.parse(json['lastModified']);
  }

  Map<String, dynamic> toJson() => {
    'supabaseId': supabaseId,
    'boatSupabaseId': boatSupabaseId,
    'name': name,
    'sortOrder': sortOrder,
    'isSynced': isSynced,
    'lastModified': lastModified.toIso8601String(),
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ShoppingCategory &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          boatSupabaseId == other.boatSupabaseId &&
          name == other.name &&
          sortOrder == other.sortOrder &&
          isSynced == other.isSynced &&
          lastModified == other.lastModified &&
          supabaseId == other.supabaseId;

  @override
  int get hashCode => Object.hashAll([
        id,
        boatSupabaseId,
        name,
        sortOrder,
        isSynced,
        lastModified,
        supabaseId,
      ]);

  @override
  String toString() => 'ShoppingCategory(id: $id, supabaseId: $supabaseId, '
      'boatSupabaseId: $boatSupabaseId, name: $name, '
      'sortOrder: $sortOrder, isSynced: $isSynced, '
      'lastModified: $lastModified)';
}