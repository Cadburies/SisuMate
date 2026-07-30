import '../models/models.dart';

/// One matched item whose title/description changed in the newer source
/// version. [local] is kept as-is except for these two text fields — its
/// isCompleted/completionHistory/notes/photos are never touched.
class CommunityMergeUpdate {
  final ChecklistItem local;
  final String newTitle;
  final String? newDescription;
  const CommunityMergeUpdate({
    required this.local,
    required this.newTitle,
    required this.newDescription,
  });
}

/// Result of diffing a group's current local items against a newer source
/// template's content — never destructive: [toAdd] are new, [toUpdate] keep
/// their local state and only get text refreshed, and anything not matched
/// (an existing item the source no longer lists, or a completely unrelated
/// item the user added themselves) is left alone entirely (not represented
/// here at all, since nothing needs to happen to it).
class CommunityMergeDiff {
  final List<ChecklistItem> toAdd;
  final List<CommunityMergeUpdate> toUpdate;
  final int keptCount;
  const CommunityMergeDiff({
    required this.toAdd,
    required this.toUpdate,
    required this.keptCount,
  });

  bool get isEmpty => toAdd.isEmpty && toUpdate.isEmpty;
}

/// Matches items by title (case-insensitive, trimmed) — the same identity
/// key `ImportService.contentKeyChecklist` uses for the existing checklist
/// import/export merge, so this behaves consistently with that feature.
CommunityMergeDiff computeCommunityMergeDiff({
  required List<ChecklistItem> localItems,
  required Map<String, dynamic> parsedContent,
  required String groupSupabaseId,
  required String boatSupabaseId,
}) {
  final rawItems = parsedContent['items'] as List<dynamic>? ?? [];
  final localByKey = <String, ChecklistItem>{
    for (final i in localItems) i.title.toLowerCase().trim(): i,
  };
  final matchedKeys = <String>{};
  final toAdd = <ChecklistItem>[];
  final toUpdate = <CommunityMergeUpdate>[];

  for (final entry in rawItems.asMap().entries) {
    final idx = entry.key;
    final raw = entry.value as Map<String, dynamic>;
    final newTitle = raw['title'] as String? ?? '';
    final newDescription = raw['description'] as String?;
    final key = newTitle.toLowerCase().trim();
    final match = localByKey[key];

    if (match != null) {
      matchedKeys.add(key);
      if (match.title != newTitle || match.description != newDescription) {
        toUpdate.add(CommunityMergeUpdate(
          local: match,
          newTitle: newTitle,
          newDescription: newDescription,
        ));
      }
    } else {
      toAdd.add(ChecklistItem()
        ..supabaseId =
            '${groupSupabaseId}_item_${DateTime.now().millisecondsSinceEpoch}_$idx'
        ..boatSupabaseId = boatSupabaseId
        ..groupSupabaseId = groupSupabaseId
        ..name = raw['name'] as String? ?? ''
        ..title = newTitle
        ..description = newDescription
        ..isBundled = false
        ..createdAt = DateTime.now()
        ..lastModified = DateTime.now().toUtc()
        ..sortOrder = localItems.length + toAdd.length);
    }
  }

  final keptCount = localItems.length - matchedKeys.length;
  return CommunityMergeDiff(
      toAdd: toAdd, toUpdate: toUpdate, keptCount: keptCount);
}
