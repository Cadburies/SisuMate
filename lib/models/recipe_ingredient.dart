part of 'models.dart';

class RecipeIngredient {
  int id = 0;
  String supabaseId = '';
  String recipeSupabaseId = '';
  String name = '';
  double? quantity;
  String? unit;
  String? substitute;
  bool isGarnish = false;
  String? garnishNotes;
  bool isOptional = false;
  String? photoUrl;
  int sortOrder = 0;
  bool isSynced = false;
  DateTime lastModified = DateTime.now().toUtc();

  factory RecipeIngredient.fromJson(Map<String, dynamic> json) {
    return RecipeIngredient()
      ..supabaseId = json['supabaseId'] ?? ''
      ..recipeSupabaseId = json['recipeSupabaseId'] ?? ''
      ..name = json['name'] ?? ''
      ..quantity = (json['quantity'] as num?)?.toDouble()
      ..unit = json['unit']
      ..substitute = json['substitute']
      ..isGarnish = json['isGarnish'] ?? false
      ..garnishNotes = json['garnishNotes']
      ..isOptional = json['isOptional'] ?? false
      ..photoUrl = json['photoUrl']
      ..sortOrder = json['sortOrder'] ?? 0
      ..isSynced = json['isSynced'] ?? false
      ..lastModified = DateTime.parse(json['lastModified']);
  }

  RecipeIngredient();

  Map<String, dynamic> toJson() => {
    'supabaseId': supabaseId,
    'recipeSupabaseId': recipeSupabaseId,
    'name': name,
    'quantity': quantity,
    'unit': unit,
    'substitute': substitute,
    'isGarnish': isGarnish,
    'garnishNotes': garnishNotes,
    'isOptional': isOptional,
    'photoUrl': photoUrl,
    'sortOrder': sortOrder,
    'isSynced': isSynced,
    'lastModified': lastModified.toIso8601String(),
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RecipeIngredient &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          supabaseId == other.supabaseId &&
          recipeSupabaseId == other.recipeSupabaseId &&
          name == other.name &&
          quantity == other.quantity &&
          unit == other.unit &&
          substitute == other.substitute &&
          isGarnish == other.isGarnish &&
          garnishNotes == other.garnishNotes &&
          isOptional == other.isOptional &&
          photoUrl == other.photoUrl &&
          sortOrder == other.sortOrder &&
          isSynced == other.isSynced &&
          lastModified == other.lastModified;

  @override
  int get hashCode => Object.hashAll([
        id,
        supabaseId,
        recipeSupabaseId,
        name,
        quantity,
        unit,
        substitute,
        isGarnish,
        garnishNotes,
        isOptional,
        photoUrl,
        sortOrder,
        isSynced,
        lastModified,
      ]);

  @override
  String toString() =>
      'RecipeIngredient(id: $id, supabaseId: $supabaseId, '
      'recipeSupabaseId: $recipeSupabaseId, name: $name, '
      'quantity: $quantity, unit: $unit, substitute: $substitute, '
      'isGarnish: $isGarnish, garnishNotes: $garnishNotes, '
      'isOptional: $isOptional, photoUrl: $photoUrl, '
      'sortOrder: $sortOrder, isSynced: $isSynced, '
      'lastModified: $lastModified)';
}