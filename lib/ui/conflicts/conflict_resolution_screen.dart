import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/app_router.dart';
import '../../core/colors.dart';
import '../components/sisu_tile_card.dart';
import '../../core/di.dart';
import '../../models/models.dart';
import '../../services/conflict_resolution_service.dart';
import '../../services/error_log_service.dart';

/// Pending concurrent offline edits — keep local or keep remote (T5).
class ConflictResolutionScreen extends ConsumerWidget {
  const ConflictResolutionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final conflictsAsync = ref.watch(pendingConflictsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sync Conflicts'),
      ),
      body: conflictsAsync.when(
        data: (conflicts) {
          if (conflicts.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'No pending conflicts.\nWhen the same record is edited offline on two devices, they appear here.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: SisuColors.getTextSecondaryColor(isDark),
                  ),
                ),
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
            itemCount: conflicts.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, i) {
              final c = conflicts[i];
              return _ConflictCard(conflict: c);
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }
}

class _ConflictCard extends ConsumerWidget {
  final ConflictLog conflict;
  const _ConflictCard({required this.conflict});

  static const _svc = ConflictResolutionService();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final report = _diffReport(conflict);
    final localSummary = _summary(conflict.localData);
    final remoteSummary = _summary(conflict.remoteData);
    final suggested = report?.overall;

    return SisuTileCard(
      color: SisuColors.getTileColor(isDark),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _tableLabel(conflict.table),
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: SisuColors.getTextPrimaryColor(isDark),
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              'ID: ${conflict.localSupabaseId}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: SisuColors.getTextSecondaryColor(isDark),
                  ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (report != null) ...[
              const SizedBox(height: 10),
              _SuggestionBanner(
                reason: report.overallReason,
                isDark: isDark,
              ),
              if (report.differing.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(
                  'Field differences',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                    color: SisuColors.getTextSecondaryColor(isDark),
                  ),
                ),
                const SizedBox(height: 6),
                ...report.differing.map(
                  (f) => _FieldDiffRow(diff: f, isDark: isDark),
                ),
              ],
            ] else ...[
              const SizedBox(height: 10),
              _SideBlock(
                title: 'On this device',
                body: localSummary,
                isDark: isDark,
              ),
              const SizedBox(height: 8),
              _SideBlock(
                title: 'From cloud / other device',
                body: remoteSummary,
                isDark: isDark,
              ),
            ],
            const SizedBox(height: 12),
            // Wrap so buttons never overflow on narrow phones.
            // Primary (filled) button follows BAI5 overall suggestion.
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.end,
              children: [
                if (report?.canAutoMerge == true)
                  _actionButton(
                    label: 'Merge fields',
                    primary: suggested == OverallConflictSuggestion.mergeFields,
                    onPressed: () => _resolve(
                      context,
                      ref,
                      keepLocal: false,
                      tryMerge: true,
                    ),
                  ),
                _actionButton(
                  label: 'Keep mine',
                  primary: suggested == OverallConflictSuggestion.keepMine ||
                      (suggested == OverallConflictSuggestion.mixed &&
                          report?.canAutoMerge != true),
                  onPressed: () =>
                      _resolve(context, ref, keepLocal: true),
                ),
                _actionButton(
                  label: 'Keep cloud',
                  primary: suggested == OverallConflictSuggestion.keepCloud,
                  onPressed: () =>
                      _resolve(context, ref, keepLocal: false),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _actionButton({
    required String label,
    required bool primary,
    required VoidCallback onPressed,
  }) {
    if (primary) {
      return FilledButton(onPressed: onPressed, child: Text(label));
    }
    return OutlinedButton(onPressed: onPressed, child: Text(label));
  }

  Future<void> _resolve(
    BuildContext context,
    WidgetRef ref, {
    required bool keepLocal,
    bool tryMerge = false,
  }) async {
    await ref.read(syncServiceProvider).resolveConflict(
          conflictId: conflict.id,
          keepLocal: keepLocal,
          tryMerge: tryMerge,
        );
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          tryMerge
              ? 'Merged non-conflicting fields'
              : (keepLocal ? 'Kept your version' : 'Kept cloud version'),
        ),
      ),
    );
  }

  static ConflictDiffReport? _diffReport(ConflictLog c) {
    try {
      final local = jsonDecode(c.localData) as Map<String, dynamic>;
      final remote = jsonDecode(c.remoteData) as Map<String, dynamic>;
      return _svc.buildConflictDiff(local, remote);
    } catch (e) {
      unawaited(ErrorLogService().logWarning(
        'conflict diff parse failed: $e',
        context: 'conflict_resolution_screen: _diffReport',
      ));
      return null;
    }
  }

  static String _tableLabel(String table) {
    return switch (table) {
      'boats' => 'Boat',
      'checklist_groups' => 'Checklist group',
      'checklist_items' => 'Checklist item',
      'shopping_categories' => 'Shopping category',
      'shopping_items' => 'Shopping item',
      'captain_logs' => "Captain's log",
      'maintenance_tasks' => 'Maintenance task',
      _ => table,
    };
  }

  static String _summary(String jsonStr) {
    try {
      final m = jsonDecode(jsonStr) as Map<String, dynamic>;
      final name = m['name'] ?? m['title'] ?? m['description'];
      final lm = m['lastModified'];
      final parts = <String>[
        if (name != null && '$name'.isNotEmpty) '$name',
        if (lm != null) 'Modified: $lm',
      ];
      if (parts.isEmpty) {
        return jsonStr.length > 120
            ? '${jsonStr.substring(0, 120)}...'
            : jsonStr;
      }
      return parts.join('\n');
    } catch (_) {
      return jsonStr;
    }
  }
}

class _SuggestionBanner extends StatelessWidget {
  final String reason;
  final bool isDark;
  const _SuggestionBanner({required this.reason, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: isDark
            ? SisuColors.completedBackground.withValues(alpha: 0.25)
            : SisuColors.completedBackground.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: SisuColors.completedBackground.withValues(alpha: 0.5),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.lightbulb_outline,
            size: 18,
            color: SisuColors.getTextPrimaryColor(isDark),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              reason,
              style: TextStyle(
                fontSize: 13,
                height: 1.3,
                color: SisuColors.getTextPrimaryColor(isDark),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FieldDiffRow extends StatelessWidget {
  final FieldDiff diff;
  final bool isDark;
  const _FieldDiffRow({required this.diff, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final hint = switch (diff.suggestion) {
      FieldSideSuggestion.preferMine => 'Prefer mine',
      FieldSideSuggestion.preferTheirs => 'Prefer cloud',
      FieldSideSuggestion.mergeable => 'Mergeable',
      FieldSideSuggestion.either => '',
    };
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    diff.label,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: SisuColors.getTextPrimaryColor(isDark),
                    ),
                  ),
                ),
                if (hint.isNotEmpty)
                  Text(
                    hint,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: SisuColors.getTextSecondaryColor(isDark),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Mine: ${diff.localDisplay}',
              style: TextStyle(
                fontSize: 12,
                height: 1.25,
                color: SisuColors.getTextPrimaryColor(isDark),
              ),
            ),
            Text(
              'Cloud: ${diff.remoteDisplay}',
              style: TextStyle(
                fontSize: 12,
                height: 1.25,
                color: SisuColors.getTextPrimaryColor(isDark),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SideBlock extends StatelessWidget {
  final String title;
  final String body;
  final bool isDark;

  const _SideBlock({
    required this.title,
    required this.body,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 12,
              color: SisuColors.getTextSecondaryColor(isDark),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            body,
            style: TextStyle(
              color: SisuColors.getTextPrimaryColor(isDark),
              height: 1.25,
            ),
          ),
        ],
      ),
    );
  }
}

/// Compact drawer row with optional badge count.
class ConflictsDrawerTile extends ConsumerWidget {
  const ConflictsDrawerTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final countAsync = ref.watch(pendingConflictCountProvider);
    final count = countAsync.asData?.value ?? 0;

    return ListTile(
      leading: Badge(
        isLabelVisible: count > 0,
        label: Text('$count'),
        child: const Icon(Icons.merge_type),
      ),
      title: const Text('Sync Conflicts'),
      subtitle: Text(
        count == 0
            ? 'No pending conflicts'
            : '$count need${count == 1 ? 's' : ''} your decision',
      ),
      onTap: () {
        Navigator.of(context).pop(); // close drawer
        context.push(AppRoutes.conflicts);
      },
    );
  }
}

