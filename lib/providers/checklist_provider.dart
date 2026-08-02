import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/models.dart';
import '../core/di.dart';

// Service is replaced by Repository usage, but we can keep a provider for easy access if needed
// or just access repository directly in UI commands.

final checklistGroupsProvider =
    StreamProvider.family<List<ChecklistGroup>, String?>((ref, appType) {
      final repository = ref.watch(checklistRepositoryProvider);
      return repository.watchGroups(appType: appType);
    });

final checklistItemsProvider =
    StreamProvider.family<List<ChecklistItem>, String>((ref, groupSupabaseId) {
      final repository = ref.watch(checklistRepositoryProvider);
      return repository.watchItems(groupSupabaseId);
    });

/// #210: every item across an appType's non-hidden groups, in one join
/// query — for callers that need to search/filter across item content
/// without fanning out into a per-group `checklistItemsProvider` watch each
/// (the #207 N-watch cascade problem). See `watchItemsForAppType`.
final checklistItemsForAppTypeProvider =
    StreamProvider.family<List<ChecklistItem>, String>((ref, appType) {
      final repository = ref.watch(checklistRepositoryProvider);
      return repository.watchItemsForAppType(appType);
    });

/// #210: buckets a flat item list (as watched via
/// [checklistItemsForAppTypeProvider]) by `groupSupabaseId`.
Map<String, List<ChecklistItem>> groupItemsByGroup(
    AsyncValue<List<ChecklistItem>> itemsAsync) {
  final byGroup = <String, List<ChecklistItem>>{};
  for (final item in itemsAsync.asData?.value ?? const <ChecklistItem>[]) {
    byGroup.putIfAbsent(item.groupSupabaseId, () => []).add(item);
  }
  return byGroup;
}

/// #210: does [group] match [query] either by its own title, or by any
/// (non-hidden) item's title/name/description? [matchedItemText] is the
/// matched item's display text when the match came from item content, not
/// the group's own title — the caller shows this as a "why it matched"
/// hint, since a title-less match would otherwise look unexplained.
({bool matches, String? matchedItemText}) matchGroupSearch({
  required ChecklistGroup group,
  required String query,
  required List<ChecklistItem> itemsInGroup,
}) {
  if (query.isEmpty) return (matches: true, matchedItemText: null);
  final q = query.toLowerCase();
  if (group.title.toLowerCase().contains(q)) {
    return (matches: true, matchedItemText: null);
  }
  for (final item in itemsInGroup) {
    if (item.isHidden) continue;
    final display = item.title.isNotEmpty ? item.title : item.name;
    final haystack =
        '$display ${item.name} ${item.description ?? ''}'.toLowerCase();
    if (haystack.contains(q)) {
      return (matches: true, matchedItemText: display);
    }
  }
  return (matches: false, matchedItemText: null);
}
