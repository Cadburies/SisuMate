import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/di.dart';
import '../../models/models.dart';
import '../../services/error_log_service.dart';
import '../../services/revenuecat_service.dart';

/// Result of [AddChecklistItemFormDialog] when the user confirms Add.
class ChecklistItemFormResult {
  final String title;
  final String? notes;
  const ChecklistItemFormResult({required this.title, this.notes});
}

/// Pure title/notes form for custom checklist / maintenance / safety items.
/// Public for TEST5 widget tests — no Pro gate, no repository.
class AddChecklistItemFormDialog extends StatefulWidget {
  final String itemNoun;
  const AddChecklistItemFormDialog({
    super.key,
    this.itemNoun = 'item',
  });

  @override
  State<AddChecklistItemFormDialog> createState() =>
      AddChecklistItemFormDialogState();
}

class AddChecklistItemFormDialogState extends State<AddChecklistItemFormDialog> {
  final _titleCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  @override
  void dispose() {
    _titleCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Add ${widget.itemNoun}'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _titleCtrl,
              decoration: const InputDecoration(
                labelText: 'Title',
                border: OutlineInputBorder(),
              ),
              autofocus: true,
              textCapitalization: TextCapitalization.sentences,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _notesCtrl,
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
          onPressed: () => Navigator.of(context).pop<ChecklistItemFormResult>(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _titleCtrl.text.trim().isEmpty
              ? null
              : () {
                  final title = _titleCtrl.text.trim();
                  final notes = _notesCtrl.text.trim();
                  Navigator.of(context).pop(
                    ChecklistItemFormResult(
                      title: title,
                      notes: notes.isEmpty ? null : notes,
                    ),
                  );
                },
          child: const Text('Add'),
        ),
      ],
    );
  }
}

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

  final messenger = ScaffoldMessenger.of(context);

  final result = await showDialog<ChecklistItemFormResult>(
    context: context,
    builder: (dialogContext) => AddChecklistItemFormDialog(itemNoun: itemNoun),
  );

  if (result == null || result.title.isEmpty) return;

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
      ..title = result.title
      ..name = result.title
      ..notes = result.notes
      ..isBundled = false
      ..sortOrder = maxSort + 1
      ..lastModified = DateTime.now().toUtc()
      ..createdAt = DateTime.now();

    await ref.read(checklistRepositoryProvider).addItem(item);
    messenger.showSnackBar(
      SnackBar(content: Text('${result.title} added')),
    );
  } catch (e, st) {
    unawaited(ErrorLogService()
        .logException(e, st, context: 'add_checklist_item_dialog: addItem'));
    messenger.showSnackBar(
      SnackBar(content: Text('Failed to add $itemNoun: $e')),
    );
  }
}
