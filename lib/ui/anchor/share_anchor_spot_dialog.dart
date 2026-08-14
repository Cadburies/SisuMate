import 'package:flutter/material.dart';

import '../../models/models.dart';

/// #328 — publish a *saved* spot. Never the live watch GPS.
class ShareAnchorSpotResult {
  final bool includeCoordinates;
  final String description;
  const ShareAnchorSpotResult({
    required this.includeCoordinates,
    required this.description,
  });
}

Future<ShareAnchorSpotResult?> showShareAnchorSpotDialog(
  BuildContext context,
  AnchorSpot spot,
) {
  var includeCoords = spot.hasCoordinates;
  final descCtrl = TextEditingController(text: spot.comments);

  return showDialog<ShareAnchorSpotResult>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setDialogState) => AlertDialog(
        title: Text('Share "${spot.name}"'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Chip(label: Text('Anchorages')),
              const SizedBox(height: 12),
              TextField(
                controller: descCtrl,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 8),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Include drop coordinates'),
                subtitle: const Text(
                  'Off keeps name, notes, and danger-zone shape only.',
                ),
                value: includeCoords,
                onChanged: spot.hasCoordinates
                    ? (v) => setDialogState(() => includeCoords = v)
                    : null,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(
              ShareAnchorSpotResult(
                includeCoordinates: includeCoords,
                description: descCtrl.text.trim(),
              ),
            ),
            child: const Text('Publish'),
          ),
        ],
      ),
    ),
  );
}
