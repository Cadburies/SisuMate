import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sisu_mate/data/drift/app_database.dart';
import 'package:sisu_mate/data/repositories/maintenance_repository_impl.dart';
import 'package:sisu_mate/models/models.dart';

import '../test_helpers/db_test_helper.dart';

// MaintenanceTask on Drift (S1), sync-participating.
void main() {
  late AppDatabase db;
  late MaintenanceRepositoryImpl repo;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = MaintenanceRepositoryImpl(db, testSyncService());
  });

  tearDown(() async => db.close());

  group('MaintenanceRepositoryImpl (Drift) CRUD', () {
    test('Create persists a new task', () async {
      await repo.addTask(MaintenanceTask()
        ..supabaseId = 'm_1'
        ..description = 'Oil change'
        ..intervalHours = 250);

      final all = await repo.watchTasks().first;
      expect(all, hasLength(1));
      expect(all.single.description, 'Oil change');
      expect(all.single.intervalHours, 250);
    });

    test('watchTasks excludes hidden tasks', () async {
      await repo.addTask(MaintenanceTask()
        ..supabaseId = 'm_visible'
        ..description = 'Visible');
      await repo.addTask(MaintenanceTask()
        ..supabaseId = 'm_hidden'
        ..description = 'Hidden'
        ..isHidden = true);

      final all = await repo.watchTasks().first;
      expect(all.map((t) => t.description), ['Visible']);
    });

    test('Update persists field changes', () async {
      final task = MaintenanceTask()
        ..supabaseId = 'm_1'
        ..description = 'Draft';
      await repo.addTask(task);

      task
        ..description = 'Final'
        ..doneBy = 'Jo';
      await repo.updateTask(task);

      final all = await repo.watchTasks().first;
      expect(all.single.description, 'Final');
      expect(all.single.doneBy, 'Jo');
    });

    test('Delete removes it', () async {
      final task = MaintenanceTask()..supabaseId = 'm_1';
      await repo.addTask(task);
      await repo.deleteTask(task);
      expect(await repo.watchTasks().first, isEmpty);
    });
  });
}
