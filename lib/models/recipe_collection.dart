part of 'models.dart';

class RecipeCollection {
  int id = 0;
  String name = '';
  List<String> recipeSupabaseIds = []; // Recipe.supabaseId, menu or cocktail
  DateTime createdAt = DateTime.now();
  DateTime lastModified = DateTime.now().toUtc();

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RecipeCollection &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          listEquals(recipeSupabaseIds, other.recipeSupabaseIds) &&
          createdAt == other.createdAt &&
          lastModified == other.lastModified;

  @override
  int get hashCode => Object.hashAll([
        id,
        name,
        Object.hashAll(recipeSupabaseIds),
        createdAt,
        lastModified,
      ]);

  @override
  String toString() => 'RecipeCollection(id: $id, name: $name, '
      'recipeSupabaseIds: $recipeSupabaseIds, createdAt: $createdAt, '
      'lastModified: $lastModified)';
}
