import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sisu_mate/data/drift/app_database.dart';
import 'package:sisu_mate/data/repositories/collection_repository_impl.dart';
import 'package:sisu_mate/models/models.dart';

// RecipeCollection is on Drift (S1) — in-memory Drift, through the repo.
void main() {
  late AppDatabase db;
  late CollectionRepositoryImpl repo;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = CollectionRepositoryImpl(db);
  });

  tearDown(() async => db.close());

  group('CollectionRepositoryImpl (Drift) CRUD', () {
    test('Create: addCollection persists a new collection', () async {
      await repo.addCollection(RecipeCollection()..name = 'Boat Party Menu');

      final all = await repo.watchCollections().first;
      expect(all, hasLength(1));
      expect(all.single.name, 'Boat Party Menu');
    });

    test('Read: watchCollections emits collections sorted by name', () async {
      await repo.addCollection(RecipeCollection()..name = 'Zebra Collection');
      await repo.addCollection(RecipeCollection()..name = 'Anchor Collection');

      final collections = await repo.watchCollections().first;
      expect(collections.map((c) => c.name),
          ['Anchor Collection', 'Zebra Collection']);
    });

    test('Update: updateCollection persists field changes', () async {
      await repo.addCollection(RecipeCollection()..name = 'Draft Name');

      final saved = (await repo.watchCollections().first).single;
      saved
        ..name = 'Final Name'
        ..recipeSupabaseIds = ['recipe_1', 'recipe_2'];
      await repo.updateCollection(saved);

      final all = await repo.watchCollections().first;
      expect(all.single.name, 'Final Name');
      expect(all.single.recipeSupabaseIds, ['recipe_1', 'recipe_2']);
    });

    test('Delete: deleteCollection removes it from the database', () async {
      await repo.addCollection(RecipeCollection()..name = 'To remove');

      final saved = (await repo.watchCollections().first).single;
      await repo.deleteCollection(saved);

      expect(await repo.watchCollections().first, isEmpty);
    });
  });
}
