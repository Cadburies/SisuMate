import 'package:flutter_test/flutter_test.dart';
import 'package:sisu_mate/models/models.dart';
import 'package:sisu_mate/services/community_merge.dart';

// Covers computeCommunityMergeDiff (S5 versioning) — the non-destructive
// merge used when updating an already-imported community list to a newer
// version. Per explicit product decision: new items are added, matched
// items get their text refreshed but keep local state, and anything with no
// match in the new source is left completely alone (never deleted).
void main() {
  group('computeCommunityMergeDiff', () {
    test('a source item with no local match is queued to add', () {
      final diff = computeCommunityMergeDiff(
        localItems: const [],
        parsedContent: {
          'items': [
            {'name': 'vhf', 'title': 'VHF Radio Watch', 'description': 'Monitor ch16'},
          ],
        },
        groupSupabaseId: 'group_1',
        boatSupabaseId: 'boat_1',
      );
      expect(diff.toAdd.length, 1);
      expect(diff.toAdd.first.title, 'VHF Radio Watch');
      expect(diff.toUpdate, isEmpty);
      expect(diff.keptCount, 0);
    });

    test('a matched item with unchanged text needs no action', () {
      final local = ChecklistItem()
        ..supabaseId = 'item_1'
        ..title = 'VHF Radio Watch'
        ..description = 'Monitor ch16'
        ..isCompleted = true;
      final diff = computeCommunityMergeDiff(
        localItems: [local],
        parsedContent: {
          'items': [
            {'name': 'vhf', 'title': 'VHF Radio Watch', 'description': 'Monitor ch16'},
          ],
        },
        groupSupabaseId: 'group_1',
        boatSupabaseId: 'boat_1',
      );
      expect(diff.toAdd, isEmpty);
      expect(diff.toUpdate, isEmpty);
      expect(diff.keptCount, 0);
      expect(diff.isEmpty, isTrue);
    });

    test(
        'a matched item with changed description is queued to update, '
        'and the local item reference is preserved (state not touched here)',
        () {
      final local = ChecklistItem()
        ..supabaseId = 'item_1'
        ..title = 'VHF Radio Watch'
        ..description = 'Old description'
        ..isCompleted = true
        ..completionHistory = ['2026-01-01T00:00:00.000Z'];
      final diff = computeCommunityMergeDiff(
        localItems: [local],
        parsedContent: {
          'items': [
            {
              'name': 'vhf',
              'title': 'VHF Radio Watch',
              'description': 'Updated description text',
            },
          ],
        },
        groupSupabaseId: 'group_1',
        boatSupabaseId: 'boat_1',
      );
      expect(diff.toAdd, isEmpty);
      expect(diff.toUpdate.length, 1);
      expect(diff.toUpdate.first.newDescription, 'Updated description text');
      // The diff only carries the new text — it's the caller's job to apply
      // just title/description and leave isCompleted/completionHistory
      // untouched, which is exactly what CommunityRepositoryImpl does.
      expect(diff.toUpdate.first.local.isCompleted, isTrue);
      expect(diff.toUpdate.first.local.completionHistory, isNotEmpty);
      expect(diff.keptCount, 0);
    });

    test('a local item with no match in the new source is kept, not deleted', () {
      final local = ChecklistItem()
        ..supabaseId = 'item_extra'
        ..title = 'My Custom Item'
        ..description = 'Added by me, not from the template';
      final diff = computeCommunityMergeDiff(
        localItems: [local],
        parsedContent: {'items': <Map<String, dynamic>>[]},
        groupSupabaseId: 'group_1',
        boatSupabaseId: 'boat_1',
      );
      expect(diff.toAdd, isEmpty);
      expect(diff.toUpdate, isEmpty);
      expect(diff.keptCount, 1);
    });

    test('matching is case-insensitive and trims whitespace', () {
      final local = ChecklistItem()
        ..supabaseId = 'item_1'
        ..title = '  VHF Radio Watch  '
        ..description = 'Monitor ch16';
      final diff = computeCommunityMergeDiff(
        localItems: [local],
        parsedContent: {
          'items': [
            {'name': 'vhf', 'title': 'vhf radio watch', 'description': 'Monitor ch16'},
          ],
        },
        groupSupabaseId: 'group_1',
        boatSupabaseId: 'boat_1',
      );
      expect(diff.toAdd, isEmpty, reason: 'should have matched despite case/whitespace');
      expect(diff.keptCount, 0);
    });

    test('empty on both sides yields an empty diff', () {
      final diff = computeCommunityMergeDiff(
        localItems: const [],
        parsedContent: {'items': <Map<String, dynamic>>[]},
        groupSupabaseId: 'group_1',
        boatSupabaseId: 'boat_1',
      );
      expect(diff.isEmpty, isTrue);
      expect(diff.keptCount, 0);
    });

    test('a realistic mixed update: one add, one update, one kept', () {
      final unchanged = ChecklistItem()
        ..supabaseId = 'i1'
        ..title = 'Bilge Check'
        ..description = 'Check bilge pump';
      final toChange = ChecklistItem()
        ..supabaseId = 'i2'
        ..title = 'Fuel Filter'
        ..description = 'Old instructions'
        ..isCompleted = true;
      final extra = ChecklistItem()
        ..supabaseId = 'i3'
        ..title = 'My Own Addition'
        ..description = 'Not from template';

      final diff = computeCommunityMergeDiff(
        localItems: [unchanged, toChange, extra],
        parsedContent: {
          'items': [
            {'name': 'bilge', 'title': 'Bilge Check', 'description': 'Check bilge pump'},
            {'name': 'fuel', 'title': 'Fuel Filter', 'description': 'New instructions'},
            {'name': 'new', 'title': 'Impeller Check', 'description': 'Inspect impeller'},
          ],
        },
        groupSupabaseId: 'group_1',
        boatSupabaseId: 'boat_1',
      );

      expect(diff.toAdd.length, 1);
      expect(diff.toAdd.first.title, 'Impeller Check');
      expect(diff.toUpdate.length, 1);
      expect(diff.toUpdate.first.local.supabaseId, 'i2');
      expect(diff.toUpdate.first.newDescription, 'New instructions');
      expect(diff.keptCount, 1);
    });
  });
}
