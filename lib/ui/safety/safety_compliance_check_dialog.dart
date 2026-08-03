import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/app_router.dart';
import '../../providers/shopping_provider.dart' show activeBoatProvider;
import '../../services/llm_client_service.dart';
import '../../services/llm_payload_builder.dart';

/// #226: same document-grounded-reasoning shape as #222's
/// [WarrantyCheckDialog] — the user pastes an excerpt from a flare/life-raft/
/// EPIRB/fire-extinguisher service manual or certification card alongside
/// the item's current state (last service date, visible condition, expiry
/// markings), and the LLM assesses whether it looks still compliant/in-date.
/// Conservatively scoped to pasted text only — no OCR/photo reading of an
/// actual certification tag. Reached only via the safety item's AI badge
/// (#208 separation — never blended into the tile's offline Complete/Hide
/// actions).
class SafetyComplianceCheckDialog extends ConsumerStatefulWidget {
  const SafetyComplianceCheckDialog({super.key});

  @override
  ConsumerState<SafetyComplianceCheckDialog> createState() =>
      _SafetyComplianceCheckDialogState();
}

class _SafetyComplianceCheckDialogState
    extends ConsumerState<SafetyComplianceCheckDialog> {
  final _itemCtrl = TextEditingController();
  final _excerptCtrl = TextEditingController();
  LlmResult? _result;
  bool _loading = false;

  @override
  void dispose() {
    _itemCtrl.dispose();
    _excerptCtrl.dispose();
    super.dispose();
  }

  Future<void> _ask() async {
    final item = _itemCtrl.text.trim();
    final excerpt = _excerptCtrl.text.trim();
    if (item.isEmpty || excerpt.isEmpty) return;

    setState(() {
      _loading = true;
      _result = null;
    });

    final boat = await ref.read(activeBoatProvider.future);
    final payload = LlmPayloadBuilder.safetyComplianceQuery(
      itemDescription: item,
      excerptText: excerpt,
    );
    final result = await LlmClientService().complete(
      boat: boat,
      systemPrompt: 'You are a boat safety-equipment assistant. Given a '
          'description of a safety item\'s current state (last service '
          'date, visible condition, expiry markings) and a pasted excerpt '
          'from its service manual or certification card, assess whether '
          'it looks still compliant/in-date and explain your reasoning by '
          'pointing to what in the excerpt supports it. If the excerpt '
          'doesn\'t say enough to tell, say so plainly. Be concise.',
      prompt: jsonEncode(payload),
    );
    if (mounted) setState(() { _loading = false; _result = result; });
  }

  @override
  Widget build(BuildContext context) {
    final result = _result;
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.auto_awesome, color: Colors.deepPurple, size: 20),
          SizedBox(width: 8),
          Expanded(
            child: Text('AI: Compliance check', overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _itemCtrl,
                maxLines: 3,
                minLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Item & current state',
                  helperText: 'What is it, last service date, visible '
                      'condition, expiry markings.',
                  helperMaxLines: 2,
                ),
                enabled: !_loading,
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _excerptCtrl,
                maxLines: 8,
                minLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Manual / certification excerpt',
                  helperText: 'Paste the relevant service interval or '
                      'certification section — not the whole document.',
                  helperMaxLines: 2,
                ),
                enabled: !_loading,
              ),
              const SizedBox(height: 12),
              if (_loading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (result != null)
                _ResultView(result: result),
            ],
          ),
        ),
      ),
      actions: [
        if (result?.status == LlmResultStatus.noKeyConfigured)
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.push(AppRoutes.settings);
            },
            child: const Text('Go to Settings'),
          ),
        TextButton(
          onPressed: _loading ? null : _ask,
          child: const Text('Ask'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }
}

class _ResultView extends StatelessWidget {
  final LlmResult result;
  const _ResultView({required this.result});

  @override
  Widget build(BuildContext context) {
    if (result.status != LlmResultStatus.success) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline,
              size: 18, color: Theme.of(context).colorScheme.error),
          const SizedBox(width: 8),
          Expanded(child: Text(result.errorMessage ?? 'Something went wrong.')),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(result.text ?? ''),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.info_outline,
                size: 16, color: Theme.of(context).colorScheme.secondary),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                'This is an AI reading of the text you pasted, not a '
                'certified inspection — confirm with a certified '
                'inspector/service agent before relying on it.',
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(fontStyle: FontStyle.italic),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
