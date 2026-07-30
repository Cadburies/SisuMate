part of 'models.dart';

class Boat {
  Boat();

  int id = 0;
  bool isBought = false;
  bool isHidden = false;
  bool isSynced = false;
  DateTime lastModified = DateTime.now().toUtc();
  double? lastPurchasePrice;
  String name = '';
  String? notes;
  String? origin;
  String? photoUrl;
  String supabaseId = '';
  // ownerId: pushed + read (only owners write boats; used by RLS — SHARE6).
  // shareCode: inbound-only (DB-generated), never pushed.
  String? ownerId;
  String? shareCode;

  factory Boat.fromJson(Map<String, dynamic> json) {
    return Boat()
      ..isBought = json['isBought'] ?? false
      ..isHidden = json['isHidden'] ?? false
      ..isSynced = json['isSynced'] ?? false
      ..lastModified = DateTime.parse(json['lastModified'])
      ..lastPurchasePrice = json['lastPurchasePrice']?.toDouble()
      ..name = json['name'] ?? ''
      ..notes = json['notes']
      ..origin = json['origin']
      ..photoUrl = json['photoUrl']
      ..supabaseId = json['supabaseId'] ?? ''
      ..ownerId = json['ownerId']
      ..shareCode = json['shareCode'];
  }

  Map<String, dynamic> toJson() => {
    'supabaseId': supabaseId,
    'name': name,
    'isBought': isBought,
    'isHidden': isHidden,
    'isSynced': isSynced,
    'lastModified': lastModified.toIso8601String(),
    'lastPurchasePrice': lastPurchasePrice,
    'notes': notes,
    'origin': origin,
    'photoUrl': photoUrl,
    // ownerId is pushed (only owners write boats) so RLS can validate ownership
    // on insert/update. shareCode stays inbound-only (DB-generated).
    'ownerId': ownerId,
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Boat &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          isBought == other.isBought &&
          isHidden == other.isHidden &&
          isSynced == other.isSynced &&
          lastModified == other.lastModified &&
          lastPurchasePrice == other.lastPurchasePrice &&
          name == other.name &&
          notes == other.notes &&
          origin == other.origin &&
          photoUrl == other.photoUrl &&
          supabaseId == other.supabaseId &&
          ownerId == other.ownerId &&
          shareCode == other.shareCode;

  @override
  int get hashCode => Object.hashAll([
        id,
        isBought,
        isHidden,
        isSynced,
        lastModified,
        lastPurchasePrice,
        name,
        notes,
        origin,
        photoUrl,
        supabaseId,
        ownerId,
        shareCode,
      ]);

  @override
  String toString() => 'Boat(id: $id, supabaseId: $supabaseId, name: $name, '
      'isBought: $isBought, isHidden: $isHidden, isSynced: $isSynced, '
      'lastModified: $lastModified, lastPurchasePrice: $lastPurchasePrice, '
      'notes: $notes, origin: $origin, photoUrl: $photoUrl, '
      'ownerId: $ownerId, shareCode: $shareCode)';
}
