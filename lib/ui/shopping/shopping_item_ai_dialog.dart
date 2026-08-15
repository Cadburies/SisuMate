import 'package:flutter/material.dart';

import '../../models/models.dart';
import '../../services/shopping_item_local_guide.dart';

/// #317 / #337 — per-item offline guide.
///
/// Live shop names belong on the **list-level** port run (title-bar sparkle),
/// not two competing AI buttons on a single line.
class ShoppingItemAiDialog extends StatelessWidget {
  final ShoppingItem item;
  final VoidCallback? onPlanPortRun;

  const ShoppingItemAiDialog({
    super.key,
    required this.item,
    this.onPlanPortRun,
  });

  @override
  Widget build(BuildContext context) {
    final qty = item.quantity < 1 ? 1 : item.quantity;
    final unit = (item.unit != null && item.unit!.trim().isNotEmpty)
        ? ' ${item.unit!.trim()}'
        : '';
    final report = ShoppingItemLocalGuide.formatForItem(item);

    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.auto_awesome,
              color: Theme.of(context).colorScheme.primary, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Shop: ${item.name}',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '×$qty$unit · origin ${item.origin}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              if (onPlanPortRun != null) ...[
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: onPlanPortRun,
                  icon: const Icon(Icons.directions_walk, size: 18),
                  label: const Text('Plan port run for this list'),
                ),
                const SizedBox(height: 12),
              ],
              Text(report, style: const TextStyle(height: 1.35)),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    );
  }
}
