part of 'models.dart';

/// #320 — one quantity change on an [InventoryItem].
class InventoryQtyChange {
  InventoryQtyChange({
    required this.at,
    required this.from,
    required this.to,
  });

  final DateTime at;
  final double from;
  final double to;

  bool get isRestock => to > from;

  factory InventoryQtyChange.fromJson(Map<String, dynamic> json) {
    return InventoryQtyChange(
      at: DateTime.parse(json['at'] as String),
      from: (json['from'] as num).toDouble(),
      to: (json['to'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
        'at': at.toIso8601String(),
        'from': from,
        'to': to,
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is InventoryQtyChange &&
          at == other.at &&
          from == other.from &&
          to == other.to;

  @override
  int get hashCode => Object.hash(at, from, to);
}

List<InventoryQtyChange> parseInventoryQtyHistory(dynamic raw) {
  if (raw == null) return [];
  if (raw is String) {
    if (raw.isEmpty) return [];
    raw = jsonDecode(raw);
  }
  if (raw is! List) return [];
  return raw
      .whereType<Map>()
      .map((e) => InventoryQtyChange.fromJson(Map<String, dynamic>.from(e)))
      .toList();
}

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
  /// #318 — scanned/typed barcode (UPC/EAN) for quickly re-finding this
  /// item on restock; no product-name lookup (unlike Cocktails' bottle
  /// barcode database — boat spares have no equivalent curated catalog).
  String? barcode;
  /// #319 — ChecklistItem.supabaseId of the maintenance task that consumes
  /// this spare. Null = unlinked. Stored as the wire/local supabaseId (not
  /// the Drift int pk) so the link survives sync across devices.
  String? linkedMaintenanceItemSupabaseId;
  /// #320 — JSON list of [InventoryQtyChange] (timestamp + old/new qty).
  List<InventoryQtyChange> quantityHistory = [];
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
      ..barcode = json['barcode']
      ..linkedMaintenanceItemSupabaseId = json['linkedMaintenanceItemSupabaseId']
      ..quantityHistory = parseInventoryQtyHistory(json['quantityHistory'])
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
    'barcode': barcode,
    'linkedMaintenanceItemSupabaseId': linkedMaintenanceItemSupabaseId,
    'quantityHistory': quantityHistory.map((e) => e.toJson()).toList(),
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
          barcode == other.barcode &&
          linkedMaintenanceItemSupabaseId ==
              other.linkedMaintenanceItemSupabaseId &&
          listEquals(quantityHistory, other.quantityHistory) &&
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
        barcode,
        linkedMaintenanceItemSupabaseId,
        Object.hashAll(quantityHistory),
        isSynced,
        lastModified,
      ]);

  @override
  String toString() => 'InventoryItem(id: $id, supabaseId: $supabaseId, '
      'boatSupabaseId: $boatSupabaseId, name: $name, location: $location, '
      'quantity: $quantity, unit: $unit, serialNumber: $serialNumber, '
      'notes: $notes, localPath: $localPath, barcode: $barcode, '
      'linkedMaintenanceItemSupabaseId: $linkedMaintenanceItemSupabaseId, '
      'quantityHistory: $quantityHistory, '
      'isSynced: $isSynced, lastModified: $lastModified)';
}
