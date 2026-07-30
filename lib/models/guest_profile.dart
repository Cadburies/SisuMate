part of 'models.dart';

class GuestProfile {
  int id = 0;
  String name = '';
  // allergenTags: gluten | dairy | eggs | nuts | peanuts | shellfish | fish | soy | sesame | sulphites | mustard | celery | lupin | molluscs
  List<String> allergenRestrictions = [];
  // dietaryTags: vegan | vegetarian | gluten-free | dairy-free | egg-free | nut-free | keto | paleo | halal | kosher | low-carb | low-sodium
  List<String> dietaryRequirements = [];
  DateTime createdAt = DateTime.now();

  GuestProfile();

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'allergen_restrictions': allergenRestrictions,
    'dietary_requirements': dietaryRequirements,
    'created_at': createdAt.toIso8601String(),
  };

  factory GuestProfile.fromJson(Map<String, dynamic> json) => GuestProfile()
    ..name = (json['name'] as String?) ?? ''
    ..allergenRestrictions = List<String>.from(json['allergen_restrictions'] as List? ?? [])
    ..dietaryRequirements = List<String>.from(json['dietary_requirements'] as List? ?? [])
    ..createdAt = json['created_at'] != null
        ? DateTime.parse(json['created_at'] as String)
        : DateTime.now();

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GuestProfile &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          listEquals(allergenRestrictions, other.allergenRestrictions) &&
          listEquals(dietaryRequirements, other.dietaryRequirements) &&
          createdAt == other.createdAt;

  @override
  int get hashCode => Object.hashAll([
        id,
        name,
        Object.hashAll(allergenRestrictions),
        Object.hashAll(dietaryRequirements),
        createdAt,
      ]);

  @override
  String toString() => 'GuestProfile(id: $id, name: $name, '
      'allergenRestrictions: $allergenRestrictions, '
      'dietaryRequirements: $dietaryRequirements, createdAt: $createdAt)';
}
