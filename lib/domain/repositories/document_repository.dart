import '../../models/models.dart';

abstract class DocumentRepository {
  Stream<List<Document>> watchDocuments();
  Future<void> addDocument(Document document);
  Future<void> updateDocument(Document document);
  Future<void> deleteDocument(Document document);
}
