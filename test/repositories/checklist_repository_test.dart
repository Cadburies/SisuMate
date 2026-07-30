import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sisu_mate/data/drift/app_database.dart';
import 'package:sisu_mate/data/repositories/checklist_repository_impl.dart';
import 'package:sisu_mate/models/models.dart';

import '../test_helpers/db_test_helper.dart';

// Checklist (groups + items) on Drift (S1), sync-participating.
void main() {
  late AppDatabase db;
  late ChecklistRepositoryImpl repo;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = ChecklistRepositoryImpl(db, testSyncService());
  });

  tearDown(() async => db.close());

  group('ChecklistRepositoryImpl (Drift) CRUD', () {
    test('Create: createGroup persists a new group', () async {
      await repo.createGroup(ChecklistGroup()
        ..supabaseId = 'group_1'
        ..boatSupabaseId = 'boat_1'
        ..appType = 'checklist'
        ..title = 'Pre-departure');

      final all = await repo.watchGroups().first;
      expect(all, hasLength(1));
      expect(all.single.title, 'Pre-departure');
    });

    test(
        'Read: getItemsByGroup filters by group and excludes permanently-deleted items',
        () async {
      await repo.addItem(ChecklistItem()
        ..supabaseId = 'item_1'
        ..groupSupabaseId = 'group_1'
        ..title = 'Check bilge pump');
      await repo.addItem(ChecklistItem()
        ..supabaseId = 'item_2'
        ..groupSupabaseId = 'group_other'
        ..title = 'Unrelated group');

      final items = await repo.getItemsByGroup('group_1');
      expect(items, hasLength(1));
      expect(items.single.title, 'Check bilge pump');
    });

    test('PRO1: custom (non-bundled) item is added and watched for a group',
        () async {
      await repo.createGroup(ChecklistGroup()
        ..supabaseId = 'group_custom'
        ..boatSupabaseId = 'boat_1'
        ..appType = 'checklist'
        ..title = 'My list'
        ..isBundled = false);

      await repo.addItem(ChecklistItem()
        ..supabaseId = 'custom_item_1'
        ..groupSupabaseId = 'group_custom'
        ..boatSupabaseId = 'boat_1'
        ..title = 'Custom check'
        ..name = 'Custom check'
        ..notes = 'User-created'
        ..isBundled = false
        ..sortOrder = 1);

      final items = await repo.watchItems('group_custom').first;
      expect(items, hasLength(1));
      expect(items.single.title, 'Custom check');
      expect(items.single.isBundled, isFalse);
      expect(items.single.notes, 'User-created');
    });

    test('Update: toggleComplete flips isCompleted, stamps completedAt, appends history',
        () async {
      final item = ChecklistItem()
        ..supabaseId = 'item_1'
        ..groupSupabaseId = 'group_1'
        ..title = 'Check bilge pump';
      await repo.addItem(item);

      await repo.toggleComplete(item);

      final all = await repo.watchItems('group_1').first;
      expect(all.single.isCompleted, isTrue);
      expect(all.single.completedAt, isNotNull);
      expect(all.single.completionHistory, hasLength(1));

      await repo.toggleComplete(all.single); // uncomplete — no new history row
      await repo.toggleComplete(all.single); // complete again

      final again = await repo.watchItems('group_1').first;
      expect(again.single.isCompleted, isTrue);
      expect(again.single.completionHistory, hasLength(2));
    });

    test('Delete: permanentlyDelete soft-deletes (item row stays, flag flips)',
        () async {
      final item = ChecklistItem()
        ..supabaseId = 'item_1'
        ..groupSupabaseId = 'group_1'
        ..title = 'To remove';
      await repo.addItem(item);

      await repo.permanentlyDelete(item);

      // Row still exists — this is a soft delete — but is excluded from the
      // normal "items in a group" read path.
      final rows = await db.select(db.checklistItems).get();
      expect(rows, hasLength(1));
      expect(rows.single.isPermanentlyDeleted, isTrue);

      final visibleItems = await repo.getItemsByGroup('group_1');
      expect(visibleItems, isEmpty);
    });

    test('completionHistory round-trips through the JSON column', () async {
      final item = ChecklistItem()
        ..supabaseId = 'item_1'
        ..groupSupabaseId = 'group_1'
        ..title = 'Logged task'
        ..completionHistory = ['2026-07-01', '2026-07-05'];
      await repo.addItem(item);

      final saved = (await repo.watchItems('group_1').first).single;
      expect(saved.completionHistory, ['2026-07-01', '2026-07-05']);
    });
  });
}
