import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/di.dart';
import '../../models/models.dart';
import '../../services/error_log_service.dart';
import '../../services/inventory_reorder_service.dart';

/// Inventory watch used by the maintenance-item detail spare banner.
/// Separate from InventoryScreen's provider so CheckPageViewer doesn't
/// import that screen (circular via app_router).
final inventoryForSpareLinksProvider =
    StreamProvider<List<InventoryItem>>((ref) {
  return ref.watch(inventoryItemRepositoryProvider).watchInventoryItems();
});

/// #319 — after completing a maintenance checklist item, offer to decrement
/// any linked inventory spares. Skippable; never auto-decrements.
class LinkedSparePrompt {
  LinkedSparePrompt._();

  static Future<void> afterCompleting({
    required BuildContext context,
    required WidgetRef ref,
    required String checklistItemSupabaseId,
    required bool nowCompleted,
  }) async {
    if (!nowCompleted) return;
    // Prefer the already-watched provider (warm on the maintenance list /
    // item detail) so the dialog isn't racing a fresh stream subscribe.
    var inventory =
        ref.read(inventoryForSpareLinksProvider).asData?.value;
    inventory ??= await ref
        .read(inventoryItemRepositoryProvider)
        .watchInventoryItems()
        .first;
    final candidates = InventoryReorderService.linkedTo(
      inventory,
      checklistItemSupabaseId,
    ).where((i) => i.quantity > 0).toList();
    if (candidates.isEmpty || !context.mounted) return;

    final decrement = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Decrement linked spare?'),
        content: Text(_body(candidates)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Skip'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Decrement'),
          ),
        ],
      ),
    );
    if (decrement != true) return;

    final repo = ref.read(inventoryItemRepositoryProvider);
    for (final spare in candidates) {
      spare.quantity = (spare.quantity - 1).clamp(0, double.infinity);
      try {
        await repo.updateInventoryItem(spare);
      } catch (e, st) {
        ErrorLogService().logException(
          e,
          st,
          context: 'inventory: decrement linked spare',
        );
      }
    }
  }

  static String _body(List<InventoryItem> candidates) {
    if (candidates.length == 1) {
      return 'Use one ${candidates.single.name} '
          '(${InventoryReorderService.spareOnHandLabel(candidates.single)})?';
    }
    final lines = candidates
        .map(InventoryReorderService.spareOnHandLabel)
        .join('\n');
    return 'Use one of each linked spare?\n\n$lines';
  }
}
