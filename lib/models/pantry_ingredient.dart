part of 'models.dart';

class PantryIngredient {
  PantryIngredient();

  int id = 0;
  String supabaseId = '';
  String boatSupabaseId = ''; // SHARE4: per-boat scope
  String name = '';
  bool inMyPantry = false;
  /// On-hand stock only (metric). Catalog size lives in [purchaseSizeBase].
  double? quantity;
  String? unit;
  int sortOrder = 0;
  bool isBundled = false;
  bool isSynced = false;
  DateTime lastModified = DateTime.now().toUtc();

  // Classification
  String category = ''; // protein | dairy | grain | oil | acid | seasoning | herb | sweetener | sauce | tinned | condiment | vegetable | fruit | nut | baking
  List<String> flavorProfiles = [];
  List<String> cuisineTypes = [];

  // Dietary & allergen info
  // allergenTags: gluten | dairy | eggs | nuts | peanuts | shellfish | fish | soy | sesame | sulphites | mustard | celery | lupin | molluscs
  // dietaryTags:  vegan | vegetarian | gluten-free | dairy-free | egg-free | nut-free | keto | paleo | halal | kosher | low-carb | low-sodium
  List<String> allergenTags = [];
  List<String> dietaryTags = [];

  // Substitute hierarchy — what this ingredient can fill in for
  String? substitute1;
  String? substitute2;

  // Media — localPhotoPath takes priority over imageUrl in display
  String? localPhotoPath;
  String? imageUrl;

  // Expiry tracking
  DateTime? expiryDate;

  // Cost & purchase tracking
  double? lastKnownPrice;
  String priceCurrency = 'USD';
  String? lastKnownPriceUnit;
  String? lastPurchasePlace;
  List<PurchaseRecord> purchaseHistory = [];

  /// Catalog SKU — how it is sold. Independent of [quantity].
  double? purchaseSizeBase;
  String? purchaseBaseUnit;
  String? purchaseNoun;
  int unitsPerPurchase = 1;
  double? innerSizeBase;

  // Nutrition — per 100g of this ingredient
  double? caloriesPer100g;
  double? proteinPer100g;
  double? fatPer100g;
  double? carbsPer100g;

  factory PantryIngredient.fromJson(Map<String, dynamic> json) {
    return PantryIngredient()
      ..supabaseId = json['supabaseId'] ?? ''
      ..boatSupabaseId = json['boatSupabaseId'] ?? ''
      ..name = json['name'] ?? ''
      ..inMyPantry = json['inMyPantry'] ?? false
      ..quantity = (json['quantity'] as num?)?.toDouble()
      ..unit = json['unit']
      ..sortOrder = json['sortOrder'] ?? 0
      ..isBundled = json['isBundled'] ?? false
      ..isSynced = json['isSynced'] ?? false
      ..category = json['category'] ?? ''
      ..flavorProfiles = stringListFromJson(json['flavorProfiles'])
      ..cuisineTypes = stringListFromJson(json['cuisineTypes'])
      ..allergenTags = stringListFromJson(json['allergenTags'])
      ..dietaryTags = stringListFromJson(json['dietaryTags'])
      ..substitute1 = json['substitute1']
      ..substitute2 = json['substitute2']
      ..localPhotoPath = json['localPhotoPath']
      ..imageUrl = json['imageUrl']
      ..expiryDate = json['expiryDate'] != null
          ? DateTime.tryParse(json['expiryDate'] as String)
          : null
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
      ..caloriesPer100g = (json['caloriesPer100g'] as num?)?.toDouble()
      ..proteinPer100g = (json['proteinPer100g'] as num?)?.toDouble()
      ..fatPer100g = (json['fatPer100g'] as num?)?.toDouble()
      ..carbsPer100g = (json['carbsPer100g'] as num?)?.toDouble()
      ..lastModified = DateTime.parse(
          json['lastModified'] ?? DateTime.now().toUtc().toIso8601String());
  }

  Map<String, dynamic> toJson() => {
        'supabaseId': supabaseId,
        'boatSupabaseId': boatSupabaseId,
        'name': name,
        'inMyPantry': inMyPantry,
        'quantity': quantity,
        'unit': unit,
        'sortOrder': sortOrder,
        'isBundled': isBundled,
        'isSynced': isSynced,
        'category': category,
        'flavorProfiles': flavorProfiles,
        'cuisineTypes': cuisineTypes,
        'allergenTags': allergenTags,
        'dietaryTags': dietaryTags,
        'substitute1': substitute1,
        'substitute2': substitute2,
        'localPhotoPath': localPhotoPath,
        'imageUrl': imageUrl,
        'expiryDate': expiryDate?.toIso8601String(),
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
        'caloriesPer100g': caloriesPer100g,
        'proteinPer100g': proteinPer100g,
        'fatPer100g': fatPer100g,
        'carbsPer100g': carbsPer100g,
        'lastModified': lastModified.toIso8601String(),
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PantryIngredient &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          supabaseId == other.supabaseId &&
          boatSupabaseId == other.boatSupabaseId &&
          name == other.name &&
          inMyPantry == other.inMyPantry &&
          quantity == other.quantity &&
          unit == other.unit &&
          sortOrder == other.sortOrder &&
          isBundled == other.isBundled &&
          isSynced == other.isSynced &&
          lastModified == other.lastModified &&
          category == other.category &&
          listEquals(flavorProfiles, other.flavorProfiles) &&
          listEquals(cuisineTypes, other.cuisineTypes) &&
          listEquals(allergenTags, other.allergenTags) &&
          listEquals(dietaryTags, other.dietaryTags) &&
          substitute1 == other.substitute1 &&
          substitute2 == other.substitute2 &&
          localPhotoPath == other.localPhotoPath &&
          imageUrl == other.imageUrl &&
          expiryDate == other.expiryDate &&
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
          caloriesPer100g == other.caloriesPer100g &&
          proteinPer100g == other.proteinPer100g &&
          fatPer100g == other.fatPer100g &&
          carbsPer100g == other.carbsPer100g;

  @override
  int get hashCode => Object.hashAll([
        id,
        supabaseId,
        boatSupabaseId,
        name,
        inMyPantry,
        quantity,
        unit,
        sortOrder,
        isBundled,
        isSynced,
        lastModified,
        category,
        Object.hashAll(flavorProfiles),
        Object.hashAll(cuisineTypes),
        Object.hashAll(allergenTags),
        Object.hashAll(dietaryTags),
        substitute1,
        substitute2,
        localPhotoPath,
        imageUrl,
        expiryDate,
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
        caloriesPer100g,
        proteinPer100g,
        fatPer100g,
        carbsPer100g,
      ]);

  @override
  String toString() => 'PantryIngredient(id: $id, supabaseId: $supabaseId, '
      'boatSupabaseId: $boatSupabaseId, name: $name, '
      'inMyPantry: $inMyPantry, quantity: $quantity, unit: $unit, '
      'sortOrder: $sortOrder, isBundled: $isBundled, isSynced: $isSynced, '
      'lastModified: $lastModified, category: $category, '
      'flavorProfiles: $flavorProfiles, cuisineTypes: $cuisineTypes, '
      'allergenTags: $allergenTags, dietaryTags: $dietaryTags, '
      'substitute1: $substitute1, substitute2: $substitute2, '
      'localPhotoPath: $localPhotoPath, imageUrl: $imageUrl, '
      'expiryDate: $expiryDate, lastKnownPrice: $lastKnownPrice, '
      'priceCurrency: $priceCurrency, '
      'lastKnownPriceUnit: $lastKnownPriceUnit, '
      'lastPurchasePlace: $lastPurchasePlace, '
      'purchaseHistory: $purchaseHistory, purchaseSizeBase: $purchaseSizeBase, '
      'purchaseBaseUnit: $purchaseBaseUnit, purchaseNoun: $purchaseNoun, '
      'unitsPerPurchase: $unitsPerPurchase, innerSizeBase: $innerSizeBase, '
      'caloriesPer100g: $caloriesPer100g, '
      'proteinPer100g: $proteinPer100g, fatPer100g: $fatPer100g, '
      'carbsPer100g: $carbsPer100g)';
}
