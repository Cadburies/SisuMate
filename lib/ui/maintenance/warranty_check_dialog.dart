import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/app_router.dart';
import '../../providers/shopping_provider.dart' show activeBoatProvider;
import '../../services/llm_client_service.dart';
import '../../services/llm_payload_builder.dart';

/// #222: "is this covered?" — the user pastes the relevant excerpt of their
/// own boat's manual/warranty terms/wiring diagram labels alongside a
/// description of what broke, and the LLM reasons over that pasted text.
/// There is no OCR/text-extraction pipeline for `Document` (#222's scope
/// note), so this never reads a stored file directly. Reached only via the
/// maintenance item's AI menu (#208 separation — never blended into the
/// item's offline Complete/Hide/Delete actions).
class WarrantyCheckDialog extends ConsumerStatefulWidget {
  const WarrantyCheckDialog({super.key});

  @override
  ConsumerState<WarrantyCheckDialog> createState() =>
      _WarrantyCheckDialogState();
}

class _WarrantyCheckDialogState extends ConsumerState<WarrantyCheckDialog> {
  final _breakageCtrl = TextEditingController();
  final _excerptCtrl = TextEditingController();
  LlmResult? _result;
  bool _loading = false;

  @override
  void dispose() {
    _breakageCtrl.dispose();
    _excerptCtrl.dispose();
    super.dispose();
  }

  Future<void> _ask() async {
    final breakage = _breakageCtrl.text.trim();
    final excerpt = _excerptCtrl.text.trim();
    if (breakage.isEmpty || excerpt.isEmpty) return;

    setState(() {
      _loading = true;
      _result = null;
    });

    final boat = await ref.read(activeBoatProvider.future);
    final payload = LlmPayloadBuilder.warrantyQuery(
      breakageDescription: breakage,
      manualExcerpt: excerpt,
    );
    final result = await LlmClientService().complete(
      boat: boat,
      systemPrompt: 'You are a boat maintenance assistant. Given a '
          'description of a breakage and a pasted excerpt from the '
          'boat\'s own manual, warranty terms, or wiring diagram labels, '
          'assess whether the breakage looks covered and explain your '
          'reasoning by pointing to what in the excerpt supports it. If '
          'the excerpt doesn\'t say enough to tell, say so plainly. Be '
          'concise.',
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
            child:
                Text('AI: Warranty check', overflow: TextOverflow.ellipsis),
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
                controller: _breakageCtrl,
                maxLines: 3,
                minLines: 2,
                decoration: const InputDecoration(
                  labelText: 'What broke?',
                  helperText: 'Describe the failure — what happened, when.',
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
                  labelText: 'Manual / warranty excerpt',
                  helperText: 'Paste the relevant clause, manual section, '
                      'or wiring diagram labels — not the whole document.',
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
                'legal or warranty determination — confirm with the '
                'manufacturer/dealer before relying on it.',
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
