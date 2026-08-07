part of 'models.dart';

class ShoppingItem {
  ShoppingItem();

  int id = 0;
  String? boatSupabaseId;
  String categorySupabaseId = '';
  bool isBundled = false;
  bool isBought = false;
  bool isSynced = false;
  DateTime lastModified = DateTime.now().toUtc();
  String name = '';
  int quantity = 1;
  String supabaseId = '';
  String? unit;
  String? userPhotoUrl;
  bool isHidden = false;
  String? notes;
  String origin = 'spares';
  /// Expected **purchase-unit** cost for this trip line (from catalog seed
  /// or user edit) — price of one bottle/bag/pack, **not** price per ml/g.
  /// See #309: [quantity] is buy count of those packs.
  double? lastPurchasePrice;
  /// Where it was last bought / where to buy (synced with bar/pantry place).
  String? lastPurchasePlace;

  /// Line estimate: pack price × buy count (null if no pack price).
  /// [quantity] is how many packages to buy, never package size in ml/g.
  double? get lineEstimate {
    final p = lastPurchasePrice;
    if (p == null) return null;
    return p * (quantity < 1 ? 1 : quantity);
  }

  factory ShoppingItem.fromJson(Map<String, dynamic> json) {
    return ShoppingItem()
      ..supabaseId = json['supabaseId'] ?? ''
      ..boatSupabaseId = json['boatSupabaseId']
      ..categorySupabaseId = json['categorySupabaseId'] ?? ''
      ..name = json['name'] ?? ''
      ..quantity = json['quantity'] ?? 1
      ..unit = json['unit']
      ..isBought = json['isBought'] ?? false
      ..isBundled = json['isBundled'] ?? false
      ..isSynced = json['isSynced'] ?? false
      ..isHidden = json['isHidden'] ?? false
      ..notes = json['notes']
      ..origin = json['origin'] ?? 'spares'
      ..lastPurchasePrice = (json['lastPurchasePrice'] as num?)?.toDouble()
      ..lastPurchasePlace = json['lastPurchasePlace'] as String?
      ..userPhotoUrl = json['userPhotoUrl']
      ..lastModified = DateTime.parse(json['lastModified']);
  }

  Map<String, dynamic> toJson() => {
    'supabaseId': supabaseId,
    'boatSupabaseId': boatSupabaseId,
    'categorySupabaseId': categorySupabaseId,
    'name': name,
    'quantity': quantity,
    'unit': unit,
    'isBought': isBought,
    'isBundled': isBundled,
    'isSynced': isSynced,
    'isHidden': isHidden,
    'notes': notes,
    'origin': origin,
    'lastPurchasePrice': lastPurchasePrice,
    'lastPurchasePlace': lastPurchasePlace,
    'userPhotoUrl': userPhotoUrl,
    'lastModified': lastModified.toIso8601String(),
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ShoppingItem &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          boatSupabaseId == other.boatSupabaseId &&
          categorySupabaseId == other.categorySupabaseId &&
          isBundled == other.isBundled &&
          isBought == other.isBought &&
          isSynced == other.isSynced &&
          lastModified == other.lastModified &&
          name == other.name &&
          quantity == other.quantity &&
          supabaseId == other.supabaseId &&
          unit == other.unit &&
          userPhotoUrl == other.userPhotoUrl &&
          isHidden == other.isHidden &&
          notes == other.notes &&
          origin == other.origin &&
          lastPurchasePrice == other.lastPurchasePrice &&
          lastPurchasePlace == other.lastPurchasePlace;

  @override
  int get hashCode => Object.hashAll([
        id,
        boatSupabaseId,
        categorySupabaseId,
        isBundled,
        isBought,
        isSynced,
        lastModified,
        name,
        quantity,
        supabaseId,
        unit,
        userPhotoUrl,
        isHidden,
        notes,
        origin,
        lastPurchasePrice,
        lastPurchasePlace,
      ]);

  @override
  String toString() => 'ShoppingItem(id: $id, supabaseId: $supabaseId, '
      'boatSupabaseId: $boatSupabaseId, '
      'categorySupabaseId: $categorySupabaseId, name: $name, '
      'quantity: $quantity, unit: $unit, isBought: $isBought, '
      'isBundled: $isBundled, isSynced: $isSynced, isHidden: $isHidden, '
      'notes: $notes, origin: $origin, '
      'lastPurchasePrice: $lastPurchasePrice, '
      'lastPurchasePlace: $lastPurchasePlace, userPhotoUrl: $userPhotoUrl, '
      'lastModified: $lastModified)';
}