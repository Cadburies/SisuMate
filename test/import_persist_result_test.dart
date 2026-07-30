import 'package:flutter_test/flutter_test.dart';
import 'package:sisu_mate/ui/components/import_export.dart';

void main() {
  group('ImportPersistResult.snackbarMessage (SUG7)', () {
    test('nothing imported', () {
      expect(const ImportPersistResult().snackbarMessage, 'Nothing to import');
    });

    test('inserts only — singular vs plural', () {
      expect(const ImportPersistResult(inserted: 1).snackbarMessage,
          'Imported 1 item');
      expect(const ImportPersistResult(inserted: 3).snackbarMessage,
          'Imported 3 items');
    });

    test('updates only — singular vs plural', () {
      expect(const ImportPersistResult(updated: 1).snackbarMessage,
          'Updated 1 item');
      expect(const ImportPersistResult(updated: 4).snackbarMessage,
          'Updated 4 items');
    });

    test('mixed inserts and updates', () {
      expect(const ImportPersistResult(inserted: 2, updated: 1).snackbarMessage,
          'Imported 3 (2 new, 1 updated)');
    });

    test('total sums both', () {
      expect(const ImportPersistResult(inserted: 2, updated: 5).total, 7);
    });

    test('allInserted counts only inserts', () {
      final r = ImportPersistResult.allInserted(6);
      expect(r.inserted, 6);
      expect(r.updated, 0);
      expect(r.snackbarMessage, 'Imported 6 items');
    });
  });
}
