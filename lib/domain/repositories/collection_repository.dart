import '../../models/models.dart';

abstract class CollectionRepository {
  Stream<List<RecipeCollection>> watchCollections();
  Future<void> addCollection(RecipeCollection collection);
  Future<void> updateCollection(RecipeCollection collection);
  Future<void> deleteCollection(RecipeCollection collection);
}
