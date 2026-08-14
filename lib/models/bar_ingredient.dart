part of 'models.dart';

class BarIngredient {
  BarIngredient();

  int id = 0;
  String supabaseId = '';
  String boatSupabaseId = ''; // SHARE4: per-boat scope
  String name = '';
  bool inMyBar = false;
  int sortOrder = 0;
  bool isBundled = false;
  bool isSynced = false;
  DateTime lastModified = DateTime.now().toUtc();

  // Classification
  String category = ''; // spirit | liqueur | syrup | juice | mixer | bitters | garnish | rim | ice | wine
  List<String> flavorProfiles = [];
  List<String> allergenTags = [];
  double? alcoholByVolume;

  // Substitute hierarchy — what this ingredient can fill in for
  // e.g. Orange Curaçao → sub1: Triple Sec → sub2: Cointreau
  String? substitute1;
  String? substitute2;

  // Media — localPhotoPath takes priority over imageUrl (see SmartImage)
  String? localPhotoPath;
  String? imageUrl;

  // Cost & purchase tracking
  double? lastKnownPrice;
  String priceCurrency = 'USD';
  String? lastKnownPriceUnit;
  String? lastPurchasePlace;
  List<PurchaseRecord> purchaseHistory = [];

  /// Catalog SKU — how it is sold.
  double? purchaseSizeBase;
  String? purchaseBaseUnit;
  String? purchaseNoun;
  int unitsPerPurchase = 1;
  double? innerSizeBase;

  /// On-hand stock in metric (`ml` / `each`). Independent of purchase size.
  double? onHandBase;
  String? onHandUnit;

  factory BarIngredient.fromJson(Map<String, dynamic> json) {
    return BarIngredient()
      ..supabaseId = json['supabaseId'] ?? ''
      ..boatSupabaseId = json['boatSupabaseId'] ?? ''
      ..name = json['name'] ?? ''
      ..inMyBar = json['inMyBar'] ?? false
      ..sortOrder = json['sortOrder'] ?? 0
      ..isBundled = json['isBundled'] ?? false
      ..isSynced = json['isSynced'] ?? false
      ..category = json['category'] ?? ''
      ..flavorProfiles = stringListFromJson(json['flavorProfiles'])
      ..allergenTags = stringListFromJson(json['allergenTags'])
      ..alcoholByVolume = (json['alcoholByVolume'] as num?)?.toDouble()
      ..substitute1 = json['substitute1']
      ..substitute2 = json['substitute2']
      ..localPhotoPath = json['localPhotoPath']
      ..imageUrl = json['imageUrl']
      ..lastKnownPrice = (json['lastKnownPrice'] as num?)?.toDouble()
      ..priceCurrency = json['priceCurrency'] ?? 'USD'
      ..lastKnownPriceUnit = json['lastKnownPriceUnit']
      ..lastPurchasePlace = json['lastPurchasePlace']
      ..purchaseHistory = ((json['purchaseHistory'] as List?) ?? const [])
          .map((e) => PurchaseRecord.fromJson(e as Map<String, dynamic>))
          .toList()
      ..purchaseSizeBase = (json['purchaseSizeBase'] as num?)?.toDouble()
      ..purchaseBaseUnit = json['purchaseBaseUnit'] as String?
      ..purchaseNoun = json['purchaseNoun'] as String?
      ..unitsPerPurchase = (json['unitsPerPurchase'] as num?)?.toInt() ?? 1
      ..innerSizeBase = (json['innerSizeBase'] as num?)?.toDouble()
      ..onHandBase = (json['onHandBase'] as num?)?.toDouble()
      ..onHandUnit = json['onHandUnit'] as String?
      ..lastModified = DateTime.parse(
          json['lastModified'] ?? DateTime.now().toUtc().toIso8601String());
  }

  Map<String, dynamic> toJson() => {
        'supabaseId': supabaseId,
        'boatSupabaseId': boatSupabaseId,
        'name': name,
        'inMyBar': inMyBar,
        'sortOrder': sortOrder,
        'isBundled': isBundled,
        'isSynced': isSynced,
        'category': category,
        'flavorProfiles': flavorProfiles,
        'allergenTags': allergenTags,
        'alcoholByVolume': alcoholByVolume,
        'substitute1': substitute1,
        'substitute2': substitute2,
        'localPhotoPath': localPhotoPath,
        'imageUrl': imageUrl,
        'lastKnownPrice': lastKnownPrice,
        'priceCurrency': priceCurrency,
        'lastKnownPriceUnit': lastKnownPriceUnit,
        'lastPurchasePlace': lastPurchasePlace,
        'purchaseHistory': purchaseHistory.map((p) => p.toJson()).toList(),
        'purchaseSizeBase': purchaseSizeBase,
        'purchaseBaseUnit': purchaseBaseUnit,
        'purchaseNoun': purchaseNoun,
        'unitsPerPurchase': unitsPerPurchase,
        'innerSizeBase': innerSizeBase,
        'onHandBase': onHandBase,
        'onHandUnit': onHandUnit,
        'lastModified': lastModified.toIso8601String(),
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BarIngredient &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          supabaseId == other.supabaseId &&
          boatSupabaseId == other.boatSupabaseId &&
          name == other.name &&
          inMyBar == other.inMyBar &&
          sortOrder == other.sortOrder &&
          isBundled == other.isBundled &&
          isSynced == other.isSynced &&
          lastModified == other.lastModified &&
          category == other.category &&
          listEquals(flavorProfiles, other.flavorProfiles) &&
          listEquals(allergenTags, other.allergenTags) &&
          alcoholByVolume == other.alcoholByVolume &&
          substitute1 == other.substitute1 &&
          substitute2 == other.substitute2 &&
          localPhotoPath == other.localPhotoPath &&
          imageUrl == other.imageUrl &&
          lastKnownPrice == other.lastKnownPrice &&
          priceCurrency == other.priceCurrency &&
          lastKnownPriceUnit == other.lastKnownPriceUnit &&
          lastPurchasePlace == other.lastPurchasePlace &&
          listEquals(purchaseHistory, other.purchaseHistory) &&
          purchaseSizeBase == other.purchaseSizeBase &&
          purchaseBaseUnit == other.purchaseBaseUnit &&
          purchaseNoun == other.purchaseNoun &&
          unitsPerPurchase == other.unitsPerPurchase &&
          innerSizeBase == other.innerSizeBase &&
          onHandBase == other.onHandBase &&
          onHandUnit == other.onHandUnit;

  @override
  int get hashCode => Object.hashAll([
        id,
        supabaseId,
        boatSupabaseId,
        name,
        inMyBar,
        sortOrder,
        isBundled,
        isSynced,
        lastModified,
        category,
        Object.hashAll(flavorProfiles),
        Object.hashAll(allergenTags),
        alcoholByVolume,
        substitute1,
        substitute2,
        localPhotoPath,
        imageUrl,
        lastKnownPrice,
        priceCurrency,
        lastKnownPriceUnit,
        lastPurchasePlace,
        Object.hashAll(purchaseHistory),
        purchaseSizeBase,
        purchaseBaseUnit,
        purchaseNoun,
        unitsPerPurchase,
        innerSizeBase,
        onHandBase,
        onHandUnit,
      ]);

  @override
  String toString() => 'BarIngredient(id: $id, supabaseId: $supabaseId, '
      'boatSupabaseId: $boatSupabaseId, name: $name, inMyBar: $inMyBar, '
      'sortOrder: $sortOrder, isBundled: $isBundled, isSynced: $isSynced, '
      'lastModified: $lastModified, category: $category, '
      'flavorProfiles: $flavorProfiles, allergenTags: $allergenTags, '
      'alcoholByVolume: $alcoholByVolume, '
      'substitute1: $substitute1, substitute2: $substitute2, '
      'localPhotoPath: $localPhotoPath, imageUrl: $imageUrl, '
      'lastKnownPrice: $lastKnownPrice, priceCurrency: $priceCurrency, '
      'lastKnownPriceUnit: $lastKnownPriceUnit, '
      'lastPurchasePlace: $lastPurchasePlace, '
      'purchaseHistory: $purchaseHistory, purchaseSizeBase: $purchaseSizeBase, '
      'onHandBase: $onHandBase)';
}
