import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/models.dart';
import '../../providers/checklist_provider.dart';
import 'main_list_tile.dart';

/// Two-column main-list grid for checklist-style groups (Checklists,
/// Maintenance, Safety) — theme.md §5 (Chef reference).
class GroupGrid extends StatelessWidget {
  final List<ChecklistGroup> groups;
  final IconData icon;
  final Color iconColor;
  final void Function(ChecklistGroup group) onTap;
  final String countNoun; // e.g. 'items', 'tasks', 'points'
  /// #210: groupSupabaseId -> a short "why this matched" hint, shown when
  /// the group matched an active search by item content rather than its
  /// own title. Null/absent entries show no hint.
  final Map<String, String>? matchHints;

  const GroupGrid({
    super.key,
    required this.groups,
    required this.icon,
    required this.iconColor,
    required this.onTap,
    this.countNoun = 'items',
    this.matchHints,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        // Taller tiles so title + count + meta fit without RenderFlex overflow.
        childAspectRatio: 0.58,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
      ),
      itemCount: groups.length,
      itemBuilder: (context, i) {
        final group = groups[i];
        return _GroupMainListTile(
          group: group,
          icon: icon,
          iconColor: iconColor,
          countNoun: countNoun,
          matchHint: matchHints?[group.supabaseId],
          onTap: () => onTap(group),
        );
      },
    );
  }
}

class _GroupMainListTile extends ConsumerWidget {
  final ChecklistGroup group;
  final IconData icon;
  final Color iconColor;
  final String countNoun;
  final String? matchHint;
  final VoidCallback onTap;

  const _GroupMainListTile({
    required this.group,
    required this.icon,
    required this.iconColor,
    required this.countNoun,
    this.matchHint,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final itemsAsync = ref.watch(checklistItemsProvider(group.supabaseId));

    final stats = itemsAsync.when(
      data: (items) {
        final visible = items.where((i) => !i.isHidden).toList();
        final total = visible.length;
        final done = visible.where((i) => i.isCompleted).length;
        DateTime? latest;
        for (final i in visible) {
          final t = i.completedAt ?? i.lastModified;
          if (latest == null || t.isAfter(latest)) latest = t;
        }
        // Keep body compact: one count line + one secondary (meta OR attention).
        final remaining = total > 0 && done < total ? total - done : 0;
        return (
          count: total == 0
              ? 'No $countNoun yet'
              : '$done / $total $countNoun done',
          meta: remaining > 0
              ? '$remaining remaining'
              : (latest == null
                  ? (group.isBundled ? 'Bundled' : 'Custom')
                  : 'Updated ${_fmtDate(latest)}'),
          badges: <String>[
            if (total > 0 && done == total) 'Complete',
          ],
          attention: null as String?,
        );
      },
      loading: () => (
        count: '…',
        meta: null as String?,
        badges: const <String>[],
        attention: null as String?,
      ),
      error: (_, _) => (
        count: null as String?,
        meta: null as String?,
        badges: const <String>[],
        attention: null as String?,
      ),
    );

    final tags = <String>[
      if (group.origin.isNotEmpty &&
          group.origin != 'user' &&
          group.origin != 'bundled')
        group.origin,
    ];

    return MainListTile(
      onTap: onTap,
      header: MainListTile.iconHeader(
        icon: icon,
        iconColor: iconColor,
        height: 56,
      ),
      title: group.title,
      tags: tags.take(1).toList(),
      tagColor: iconColor,
      countLine: stats.count,
      metaLine: stats.meta,
      attentionLine: stats.attention,
      matchLine: matchHint,
      badges: stats.badges,
    );
  }

  static String _fmtDate(DateTime d) {
    final now = DateTime.now();
    final days = now.difference(d).inDays;
    if (days <= 0) return 'today';
    if (days == 1) return 'yesterday';
    if (days < 14) return '${days}d ago';
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }
}
