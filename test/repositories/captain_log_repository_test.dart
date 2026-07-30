import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sisu_mate/data/drift/app_database.dart';
import 'package:sisu_mate/data/repositories/captain_log_repository_impl.dart';
import 'package:sisu_mate/models/models.dart';

import '../test_helpers/db_test_helper.dart';

// CaptainLogEntry on Drift (S1), sync-participating.
void main() {
  late AppDatabase db;
  late CaptainLogRepositoryImpl repo;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = CaptainLogRepositoryImpl(db, testSyncService());
  });

  tearDown(() async => db.close());

  group('CaptainLogRepositoryImpl (Drift) CRUD', () {
    test('Create with list fields round-trips', () async {
      await repo.addLog(CaptainLogEntry()
        ..supabaseId = 'log_1'
        ..title = 'Departure'
        ..crewOnBoard = ['Ada', 'Bo']
        ..photos = ['p1.jpg']);

      final all = await repo.watchLogs().first;
      expect(all, hasLength(1));
      expect(all.single.title, 'Departure');
      expect(all.single.crewOnBoard, ['Ada', 'Bo']);
      expect(all.single.photos, ['p1.jpg']);
    });

    test('Read: watchLogs emits sorted by logDate descending', () async {
      await repo.addLog(CaptainLogEntry()
        ..supabaseId = 'log_old'
        ..logDate = DateTime(2026, 1, 1));
      await repo.addLog(CaptainLogEntry()
        ..supabaseId = 'log_new'
        ..logDate = DateTime(2026, 6, 1));

      final logs = await repo.watchLogs().first;
      expect(logs.map((l) => l.supabaseId), ['log_new', 'log_old']);
    });

    test('Update persists field changes', () async {
      final log = CaptainLogEntry()
        ..supabaseId = 'log_1'
        ..title = 'Draft';
      await repo.addLog(log);

      log
        ..title = 'Final'
        ..weather = 'Sunny';
      await repo.updateLog(log);

      final all = await repo.watchLogs().first;
      expect(all.single.title, 'Final');
      expect(all.single.weather, 'Sunny');
    });

    test('Delete removes it', () async {
      final log = CaptainLogEntry()..supabaseId = 'log_1';
      await repo.addLog(log);
      await repo.deleteLog(log);
      expect(await repo.watchLogs().first, isEmpty);
    });
  });
}
