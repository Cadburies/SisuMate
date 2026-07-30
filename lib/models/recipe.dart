part of 'models.dart';

enum RecipeType { menu, cocktail, syrup }

/// Coerces JSON/import values into a string list.
/// Accepts a list of strings, a single string, or null.
List<String> stringListFromJson(dynamic value) {
  if (value == null) return [];
  if (value is List) {
    return value
        .map((e) => e?.toString().trim() ?? '')
        .where((s) => s.isNotEmpty)
        .toList();
  }
  if (value is String) {
    final t = value.trim();
    if (t.isEmpty) return [];
    return [t];
  }
  return [];
}

/// Dedupes a string list case-insensitively while preserving first-seen casing.
List<String> dedupeStrings(Iterable<String> values) {
  final seen = <String>{};
  final out = <String>[];
  for (final v in values) {
    final t = v.trim();
    if (t.isEmpty) continue;
    if (seen.add(t.toLowerCase())) out.add(t);
  }
  return out;
}

class Recipe {
  int id = 0;
  String supabaseId = '';
  String boatSupabaseId = '';
  String name = '';
  String? description;
  String? instructions;
  String recipeType = '';
  DateTime createdAt = DateTime.now();
  bool isBundled = false;
  bool isSynced = false;
  // Recomputed by syncMissingIngredientCounts() after any bar/pantry toggle.
  int missingIngredientCount = 0;
  bool isFavourite = false;
  String? glassware;
  int? prepMinutes;
  int? cookMinutes;
  String? story;
  List<TastingRecord> tastingLog = [];
  /// Cuisine tags (e.g. `['Tiki', 'Classic']`). Empty when unset.
  List<String> cuisine = [];
  /// Flavor profile tags (e.g. `['citrus', 'tropical']`). Empty when unset.
  List<String> flavorProfiles = [];
  String? cookingMethod;
  /// Bundled asset under `assets/` (e.g. `cocktails/mai_tai.jpg`). Offline only.
  String? imageAsset;
  /// Optional user photo on device (app documents path). Offline.
  String? localPath;
  DateTime lastModified = DateTime.now().toUtc();

  factory Recipe.fromJson(Map<String, dynamic> json) {
    return Recipe()
      ..supabaseId = json['supabaseId'] ?? ''
      ..boatSupabaseId = json['boatSupabaseId'] ?? ''
      ..name = json['name'] ?? ''
      ..description = json['description']
      ..instructions = json['instructions']
      ..recipeType = json['recipeType'] ?? ''
      ..createdAt = DateTime.parse(json['createdAt'])
      ..isBundled = json['isBundled'] ?? false
      ..isSynced = json['isSynced'] ?? false
      ..missingIngredientCount = json['missingIngredientCount'] ?? 0
      ..isFavourite = json['isFavourite'] ?? false
      ..glassware = json['glassware']
      ..prepMinutes = json['prepMinutes']
      ..cookMinutes = json['cookMinutes']
      ..story = json['story']
      ..tastingLog = ((json['tastingLog'] as List?) ?? const [])
          .map((e) => TastingRecord.fromJson(e as Map<String, dynamic>))
          .toList()
      ..cuisine = stringListFromJson(json['cuisine'])
      ..flavorProfiles = stringListFromJson(json['flavorProfiles'])
      ..cookingMethod = json['cookingMethod']
      ..imageAsset = json['imageAsset']
      ..localPath = json['localPath']
      ..lastModified = DateTime.parse(json['lastModified']);
  }

  Recipe();

  Map<String, dynamic> toJson() => {
    'supabaseId': supabaseId,
    'boatSupabaseId': boatSupabaseId,
    'name': name,
    'description': description,
    'instructions': instructions,
    'recipeType': recipeType,
    'createdAt': createdAt.toIso8601String(),
    'isBundled': isBundled,
    'isSynced': isSynced,
    'missingIngredientCount': missingIngredientCount,
    'isFavourite': isFavourite,
    'glassware': glassware,
    'prepMinutes': prepMinutes,
    'cookMinutes': cookMinutes,
    'story': story,
    'tastingLog': tastingLog.map((t) => t.toJson()).toList(),
    'cuisine': cuisine,
    'flavorProfiles': flavorProfiles,
    'cookingMethod': cookingMethod,
    'imageAsset': imageAsset,
    'localPath': localPath,
    'lastModified': lastModified.toIso8601String(),
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Recipe &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          supabaseId == other.supabaseId &&
          boatSupabaseId == other.boatSupabaseId &&
          name == other.name &&
          description == other.description &&
          instructions == other.instructions &&
          recipeType == other.recipeType &&
          createdAt == other.createdAt &&
          isBundled == other.isBundled &&
          isSynced == other.isSynced &&
          missingIngredientCount == other.missingIngredientCount &&
          isFavourite == other.isFavourite &&
          glassware == other.glassware &&
          prepMinutes == other.prepMinutes &&
          cookMinutes == other.cookMinutes &&
          story == other.story &&
          listEquals(tastingLog, other.tastingLog) &&
          listEquals(cuisine, other.cuisine) &&
          listEquals(flavorProfiles, other.flavorProfiles) &&
          cookingMethod == other.cookingMethod &&
          imageAsset == other.imageAsset &&
          localPath == other.localPath &&
          lastModified == other.lastModified;

  @override
  int get hashCode => Object.hashAll([
        id,
        supabaseId,
        boatSupabaseId,
        name,
        description,
        instructions,
        recipeType,
        createdAt,
        isBundled,
        isSynced,
        missingIngredientCount,
        isFavourite,
        glassware,
        prepMinutes,
        cookMinutes,
        story,
        Object.hashAll(tastingLog),
        Object.hashAll(cuisine),
        Object.hashAll(flavorProfiles),
        cookingMethod,
        imageAsset,
        localPath,
        lastModified,
      ]);

  @override
  String toString() => 'Recipe(id: $id, supabaseId: $supabaseId, '
      'boatSupabaseId: $boatSupabaseId, name: $name, '
      'recipeType: $recipeType, description: $description, '
      'isBundled: $isBundled, isSynced: $isSynced, '
      'missingIngredientCount: $missingIngredientCount, '
      'isFavourite: $isFavourite, glassware: $glassware, '
      'prepMinutes: $prepMinutes, cookMinutes: $cookMinutes, '
      'cuisine: $cuisine, flavorProfiles: $flavorProfiles, '
      'cookingMethod: $cookingMethod, imageAsset: $imageAsset, '
      'localPath: $localPath, createdAt: $createdAt, '
      'lastModified: $lastModified)';
}
