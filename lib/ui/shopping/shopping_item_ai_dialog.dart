import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/app_router.dart';
import '../../models/models.dart';
import '../../providers/shopping_provider.dart' show activeBoatProvider;
import '../../services/llm_client_service.dart';
import '../../services/llm_payload_builder.dart';
import '../../services/shopping_item_local_guide.dart';

/// #317 — per-item shopping helper: offline guide first, optional LLM.
///
/// Prefills from the [ShoppingItem] (never an empty customs form). Customs
/// red-flags are part of the offline pack, not the primary empty-form UX.
class ShoppingItemAiDialog extends ConsumerStatefulWidget {
  final ShoppingItem item;

  const ShoppingItemAiDialog({super.key, required this.item});

  @override
  ConsumerState<ShoppingItemAiDialog> createState() =>
      _ShoppingItemAiDialogState();
}

class _ShoppingItemAiDialogState extends ConsumerState<ShoppingItemAiDialog> {
  late final TextEditingController _regionCtrl;
  late final String _offlineReport;
  LlmResult? _llm;
  bool _llmLoading = false;

  @override
  void initState() {
    super.initState();
    _regionCtrl = TextEditingController();
    _offlineReport = ShoppingItemLocalGuide.formatForItem(widget.item);
  }

  @override
  void dispose() {
    _regionCtrl.dispose();
    super.dispose();
  }

  Future<void> _runLlm() async {
    setState(() {
      _llmLoading = true;
      _llm = null;
    });
    final boat = await ref.read(activeBoatProvider.future);
    final item = widget.item;
    final result = await LlmClientService().complete(
      boat: boat,
      systemPrompt: 'You are a boat provisioning shopping assistant. '
          'Given a shopping-list line and optional region/country, suggest: '
          '(1) local product names and common brand names, '
          '(2) store types (supermarket, market, chandlery, pharmacy…), '
          '(3) a rough relative price band if you know one, '
          '(4) any customs/import cautions for yachts. '
          'Be concise with bullets. Do NOT invent live shop addresses, '
          'GPS distances, or real-time stock. Not official customs advice '
          'and not live Maps results.',
      prompt: jsonEncode(LlmPayloadBuilder.shoppingGuideQuery(
        itemName: item.name,
        origin: item.origin,
        quantity: item.quantity,
        unit: item.unit,
        notes: item.notes,
        region: _regionCtrl.text.trim().isEmpty
            ? null
            : _regionCtrl.text.trim(),
        lastPurchasePrice: item.lastPurchasePrice,
        lastPurchasePlace: item.lastPurchasePlace,
      )),
    );
    if (mounted) {
      setState(() {
        _llm = result;
        _llmLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final qty = item.quantity < 1 ? 1 : item.quantity;
    final unit = (item.unit != null && item.unit!.trim().isNotEmpty)
        ? ' ${item.unit!.trim()}'
        : '';

    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.auto_awesome, color: Colors.deepPurple, size: 20),
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
              const SizedBox(height: 12),
              Text(
                _offlineReport,
                style: const TextStyle(height: 1.35),
              ),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),
              TextField(
                controller: _regionCtrl,
                decoration: const InputDecoration(
                  labelText: 'Region / country (optional AI)',
                  helperText:
                      'e.g. Turkey, Martinique — improves local names & brands',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
              if (_llmLoading)
                const Center(child: CircularProgressIndicator())
              else
                OutlinedButton.icon(
                  onPressed: _runLlm,
                  icon: const Icon(Icons.auto_awesome, size: 18),
                  label: const Text('Improve with AI (online)'),
                ),
              if (_llm != null) ...[
                const SizedBox(height: 8),
                Text(
                  _llm!.status == LlmResultStatus.success
                      ? (_llm!.text ?? '')
                      : (_llm!.errorMessage ?? 'AI unavailable'),
                  style: const TextStyle(height: 1.35),
                ),
              ],
              const SizedBox(height: 8),
              Text(
                'Offline guide always works. AI is optional enrichment — not '
                'live shop distances or official customs advice.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
      actions: [
        if (_llm?.status == LlmResultStatus.noKeyConfigured)
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.push(AppRoutes.settings);
            },
            child: const Text('Go to Settings'),
          ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    );
  }
}
