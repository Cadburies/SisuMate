import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/di.dart';
import '../../models/models.dart';
import '../../services/revenuecat_service.dart';

/// Pro-gated "add custom item" flow for Checklists / Maintenance / Safety.
///
/// Free users are sent to the paywall. Pro users get a title (+ optional notes)
/// dialog; the new [ChecklistItem] is persisted via [checklistRepositoryProvider]
/// and appears on the group's Drift stream automatically.
Future<void> showAddCustomChecklistItemDialog({
  required BuildContext context,
  required WidgetRef ref,
  required ChecklistGroup group,
  String itemNoun = 'item',
}) async {
  final isPro = ref.read(isProProvider).value ?? false;
  if (!isPro) {
    await RevenueCatService().showPaywall(context);
    return;
  }
  if (!context.mounted) return;

  final titleCtrl = TextEditingController();
  final notesCtrl = TextEditingController();
  final messenger = ScaffoldMessenger.of(context);

  final saved = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text('Add $itemNoun'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleCtrl,
              decoration: const InputDecoration(
                labelText: 'Title',
                border: OutlineInputBorder(),
              ),
              autofocus: true,
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: notesCtrl,
              decoration: const InputDecoration(
                labelText: 'Notes (optional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
              textCapitalization: TextCapitalization.sentences,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            if (titleCtrl.text.trim().isEmpty) return;
            Navigator.of(dialogContext).pop(true);
          },
          child: const Text('Add'),
        ),
      ],
    ),
  );

  final title = titleCtrl.text.trim();
  final notes = notesCtrl.text.trim();
  titleCtrl.dispose();
  notesCtrl.dispose();

  if (saved != true || title.isEmpty) return;

  try {
    final existing =
        await ref.read(checklistRepositoryProvider).getItemsByGroup(group.supabaseId);
    var maxSort = 0;
    for (final e in existing) {
      if (e.sortOrder > maxSort) maxSort = e.sortOrder;
    }

    final item = ChecklistItem()
      ..supabaseId =
          'custom_item_${DateTime.now().millisecondsSinceEpoch}'
      ..groupSupabaseId = group.supabaseId
      ..boatSupabaseId = group.boatSupabaseId
      ..title = title
      ..name = title
      ..notes = notes.isEmpty ? null : notes
      ..isBundled = false
      ..sortOrder = maxSort + 1
      ..lastModified = DateTime.now().toUtc()
      ..createdAt = DateTime.now();

    await ref.read(checklistRepositoryProvider).addItem(item);
    messenger.showSnackBar(
      SnackBar(content: Text('$title added')),
    );
  } catch (e) {
    messenger.showSnackBar(
      SnackBar(content: Text('Failed to add $itemNoun: $e')),
    );
  }
}
