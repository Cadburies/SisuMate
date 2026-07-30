part of 'models.dart';

class InventoryItem {
  InventoryItem();

  int id = 0;
  String supabaseId = '';
  String boatSupabaseId = '';
  String name = '';
  String? location;
  double quantity = 1;
  String? unit;
  String? serialNumber;
  String? notes;
  String? localPath;
  bool isSynced = false;
  DateTime lastModified = DateTime.now().toUtc();

  factory InventoryItem.fromJson(Map<String, dynamic> json) {
    return InventoryItem()
      ..supabaseId = json['supabaseId'] ?? ''
      ..boatSupabaseId = json['boatSupabaseId'] ?? ''
      ..name = json['name'] ?? ''
      ..location = json['location']
      ..quantity = (json['quantity'] as num?)?.toDouble() ?? 1
      ..unit = json['unit']
      ..serialNumber = json['serialNumber']
      ..notes = json['notes']
      ..localPath = json['localPath']
      ..isSynced = json['isSynced'] ?? false
      ..lastModified = DateTime.parse(json['lastModified']);
  }

  Map<String, dynamic> toJson() => {
    'supabaseId': supabaseId,
    'boatSupabaseId': boatSupabaseId,
    'name': name,
    'location': location,
    'quantity': quantity,
    'unit': unit,
    'serialNumber': serialNumber,
    'notes': notes,
    'localPath': localPath,
    'isSynced': isSynced,
    'lastModified': lastModified.toIso8601String(),
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is InventoryItem &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          supabaseId == other.supabaseId &&
          boatSupabaseId == other.boatSupabaseId &&
          name == other.name &&
          location == other.location &&
          quantity == other.quantity &&
          unit == other.unit &&
          serialNumber == other.serialNumber &&
          notes == other.notes &&
          localPath == other.localPath &&
          isSynced == other.isSynced &&
          lastModified == other.lastModified;

  @override
  int get hashCode => Object.hashAll([
        id,
        supabaseId,
        boatSupabaseId,
        name,
        location,
        quantity,
        unit,
        serialNumber,
        notes,
        localPath,
        isSynced,
        lastModified,
      ]);

  @override
  String toString() => 'InventoryItem(id: $id, supabaseId: $supabaseId, '
      'boatSupabaseId: $boatSupabaseId, name: $name, location: $location, '
      'quantity: $quantity, unit: $unit, serialNumber: $serialNumber, '
      'notes: $notes, localPath: $localPath, isSynced: $isSynced, '
      'lastModified: $lastModified)';
}
