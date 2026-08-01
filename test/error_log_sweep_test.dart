import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sisu_mate/data/drift/app_database.dart';
import 'package:sisu_mate/data/repositories/community_repository_impl.dart';
import 'package:sisu_mate/data/repositories/error_log_repository_impl.dart';
import 'package:sisu_mate/services/database_service.dart';
import 'package:sisu_mate/services/error_log_service.dart';

import 'test_helpers/db_test_helper.dart';
import 'test_helpers/fake_supabase_remote.dart';

/// #122 — regression coverage proving the sweep's converted catch sites
/// actually write a row on failure, for the three named critical paths
/// (DB / sync / import).
void main() {
  late AppDatabase db;
  late ErrorLogRepositoryImpl errorLogRepo;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    errorLogRepo = ErrorLogRepositoryImpl(db);
    ErrorLogService.setInstanceForTesting(errorLogRepo);
  });

  tearDown(() async {
    ErrorLogService.resetInstanceForTests();
    await db.close();
  });

  test('DB: DatabaseService.init logs an exception on a broken database',
      () async {
    final broken = AppDatabase.forTesting(NativeDatabase.memory());
    await broken.close(); // any query against this now throws
    AppDatabase.setInstanceForTesting(broken);
    addTearDown(() => AppDatabase.setInstanceForTesting(db));

    final result = await DatabaseService().init();

    expect(result, DbInitResult.corrupted);
    final rows = await errorLogRepo.getUnprocessed();
    expect(rows, hasLength(1));
    expect(rows.single.level, 'exception');
    expect(rows.single.message, isNotEmpty);
  });

  test('Import: CommunityRepositoryImpl.importTemplate logs an exception on a remote failure',
      () async {
    final remote = FakeSupabaseRemote()
      ..templates['tmpl-1'] = {
        'id': 'tmpl-1',
        'content': '{"title": "Test", "appType": "checklist", "items": []}',
      }
      ..shouldFail = true;
    final repo = CommunityRepositoryImpl(db, null, remote);

    final ok = await repo.importTemplate('tmpl-1', 'boat-1');

    expect(ok, isFalse);
    final rows = await errorLogRepo.getUnprocessed();
    expect(rows, hasLength(1));
    expect(rows.single.level, 'exception');
    expect(rows.single.message, contains('forced failure'));
  });

  test('Sync: SyncService.processIncomingChanges logs a warning and keeps processing the batch',
      () async {
    final syncService = testSyncService();

    // A malformed row (lastModified is not a date-parseable string) should
    // be skipped with a warning, not abort the whole inbound batch.
    await syncService.processIncomingChanges('documents', [
      {
        'supabaseId': 'doc-good',
        'title': 'Passport',
        'type': 'ID',
        'lastModified': '2026-07-09T12:00:00.000',
      },
      {
        'supabaseId': 'doc-bad',
        'title': 'Broken',
        'type': 'ID',
        'lastModified': 12345, // wrong type — forces a cast failure
      },
    ]);

    final rows = await errorLogRepo.getUnprocessed();
    expect(rows, hasLength(1));
    expect(rows.single.level, 'warning');
    expect(rows.single.message, contains('documents'));
  });
}
