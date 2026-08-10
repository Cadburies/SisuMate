import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sisu_mate/data/drift/app_database.dart';
import 'package:sisu_mate/data/repositories/document_repository_impl.dart';
import 'package:sisu_mate/models/models.dart';

import '../test_helpers/db_test_helper.dart';

// Document on Drift (S1), sync-participating.
void main() {
  late AppDatabase db;
  late DocumentRepositoryImpl repo;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = DocumentRepositoryImpl(db, testSyncService());
  });

  tearDown(() async => db.close());

  group('DocumentRepositoryImpl (Drift) CRUD', () {
    test('Create: addDocument persists a new document', () async {
      await repo.addDocument(Document()
        ..supabaseId = 'doc_1'
        ..title = 'Boat Registration'
        ..type = 'Registration');

      final all = await repo.watchDocuments().first;
      expect(all, hasLength(1));
      expect(all.single.title, 'Boat Registration');
    });

    test('Read: watchDocuments emits documents sorted by title', () async {
      await repo.addDocument(Document()
        ..supabaseId = 'doc_z'
        ..title = 'Zebra Manual');
      await repo.addDocument(Document()
        ..supabaseId = 'doc_a'
        ..title = 'Anchor Warranty');

      final documents = await repo.watchDocuments().first;
      expect(documents.map((d) => d.title), ['Anchor Warranty', 'Zebra Manual']);
    });

    test('Update: updateDocument persists field changes', () async {
      final document = Document()
        ..supabaseId = 'doc_1'
        ..title = 'Draft Title';
      await repo.addDocument(document);

      document
        ..title = 'Final Title'
        ..notes = 'Renewed 2026';
      await repo.updateDocument(document);

      final all = await repo.watchDocuments().first;
      expect(all, hasLength(1));
      expect(all.single.title, 'Final Title');
      expect(all.single.notes, 'Renewed 2026');
    });

    test('#325: crewMemberSupabaseId round-trips through add and update',
        () async {
      final document = Document()
        ..supabaseId = 'doc_1'
        ..title = "Ada's Passport"
        ..type = 'Passport'
        ..crewMemberSupabaseId = 'crew_ada';
      await repo.addDocument(document);

      var all = await repo.watchDocuments().first;
      expect(all.single.crewMemberSupabaseId, 'crew_ada');

      document.crewMemberSupabaseId = null;
      await repo.updateDocument(document);
      all = await repo.watchDocuments().first;
      expect(all.single.crewMemberSupabaseId, isNull,
          reason: 'unlinking (e.g. crew member removed) must clear, not error');
    });

    test('boat-level documents default to no crew link', () async {
      await repo.addDocument(Document()
        ..supabaseId = 'doc_1'
        ..title = 'Boat Registration'
        ..type = 'Registration');

      final all = await repo.watchDocuments().first;
      expect(all.single.crewMemberSupabaseId, isNull);
    });

    test('Delete: deleteDocument removes it', () async {
      final document = Document()
        ..supabaseId = 'doc_1'
        ..title = 'To Be Deleted';
      await repo.addDocument(document);
      expect(await repo.watchDocuments().first, hasLength(1));

      await repo.deleteDocument(document);
      expect(await repo.watchDocuments().first, isEmpty);
    });
  });
}
