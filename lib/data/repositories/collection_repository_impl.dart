import 'dart:convert';
import 'package:drift/drift.dart';
import '../../models/models.dart';
import '../drift/app_database.dart';
import '../../domain/repositories/collection_repository.dart';

/// RecipeCollection on Drift (S1). `recipeSupabaseIds` is a JSON text column.
class CollectionRepositoryImpl implements CollectionRepository {
  final AppDatabase _db;
  CollectionRepositoryImpl(this._db);

  RecipeCollection _toDomain(RecipeCollectionRow r) => RecipeCollection()
    ..id = r.id
    ..name = r.name
    ..recipeSupabaseIds =
        (jsonDecode(r.recipeSupabaseIds) as List).cast<String>()
    ..createdAt = r.createdAt
    ..lastModified = r.lastModified;

  @override
  Stream<List<RecipeCollection>> watchCollections() {
    return _db.select(_db.recipeCollections).watch().map((rows) {
      final all = rows.map(_toDomain).toList();
      all.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      return all;
    });
  }

  @override
  Future<void> addCollection(RecipeCollection collection) async {
    collection.lastModified = DateTime.now().toUtc();
    await _db.into(_db.recipeCollections).insert(RecipeCollectionsCompanion.insert(
          name: Value(collection.name),
          recipeSupabaseIds: Value(jsonEncode(collection.recipeSupabaseIds)),
          createdAt: Value(collection.createdAt),
          lastModified: Value(collection.lastModified),
        ));
  }

  @override
  Future<void> updateCollection(RecipeCollection collection) async {
    collection.lastModified = DateTime.now().toUtc();
    await (_db.update(_db.recipeCollections)
          ..where((t) => t.id.equals(collection.id)))
        .write(RecipeCollectionsCompanion(
      name: Value(collection.name),
      recipeSupabaseIds: Value(jsonEncode(collection.recipeSupabaseIds)),
      lastModified: Value(collection.lastModified),
    ));
  }

  @override
  Future<void> deleteCollection(RecipeCollection collection) async {
    await (_db.delete(_db.recipeCollections)
          ..where((t) => t.id.equals(collection.id)))
        .go();
  }
}
