import 'package:drift/drift.dart';
import '../../domain/repositories/document_repository.dart';
import '../../models/models.dart';
import '../drift/app_database.dart';
import '../../services/sync_service.dart';

/// Document on Drift (S1); sync-participating.
class DocumentRepositoryImpl implements DocumentRepository {
  final AppDatabase db;
  final SyncService syncService;

  DocumentRepositoryImpl(this.db, this.syncService);

  Document _toDomain(DocumentRow r) => Document()
    ..id = r.id
    ..supabaseId = r.supabaseId
    ..boatSupabaseId = r.boatSupabaseId
    ..title = r.title
    ..type = r.type
    ..fileUrl = r.fileUrl
    ..localPath = r.localPath
    ..notes = r.notes
    ..expiry = r.expiry
    ..crewMemberSupabaseId = r.crewMemberSupabaseId
    ..isSynced = r.isSynced
    ..lastModified = r.lastModified;

  DocumentsCompanion _toCompanion(Document d) => DocumentsCompanion(
        supabaseId: Value(d.supabaseId),
        boatSupabaseId: Value(d.boatSupabaseId),
        title: Value(d.title),
        type: Value(d.type),
        fileUrl: Value(d.fileUrl),
        localPath: Value(d.localPath),
        notes: Value(d.notes),
        expiry: Value(d.expiry),
        crewMemberSupabaseId: Value(d.crewMemberSupabaseId),
        isSynced: Value(d.isSynced),
        lastModified: Value(d.lastModified),
      );

  @override
  Stream<List<Document>> watchDocuments() {
    return db.select(db.documents).watch().map((rows) {
      final all = rows.map(_toDomain).toList();
      return all
        ..sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
    });
  }

  @override
  Future<void> addDocument(Document document) async {
    document.lastModified = DateTime.now().toUtc();
    await db.into(db.documents).insert(_toCompanion(document));
    await syncService.queueOutgoingChange('documents', document.toJson());
  }

  @override
  Future<void> updateDocument(Document document) async {
    document.lastModified = DateTime.now().toUtc();
    await (db.update(db.documents)
          ..where((t) => t.supabaseId.equals(document.supabaseId)))
        .write(_toCompanion(document));
    await syncService.queueOutgoingChange('documents', document.toJson());
  }

  @override
  Future<void> deleteDocument(Document document) async {
    await (db.delete(db.documents)
          ..where((t) => t.supabaseId.equals(document.supabaseId)))
        .go();
    await syncService.queueOutgoingChange(
      'documents',
      {'supabaseId': document.supabaseId},
      isDelete: true,
    );
  }
}
