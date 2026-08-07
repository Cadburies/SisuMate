import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/app_router.dart';
import '../../providers/shopping_provider.dart' show activeBoatProvider;
import '../../services/compliance_pack_service.dart';
import '../../services/llm_client_service.dart';
import '../../services/llm_payload_builder.dart';

/// #228 / #290 / #317: list-level customs check — offline red-flag pack first,
/// optional AI on a pasted rules excerpt. Per-item shopping help uses
/// [ShoppingItemAiDialog] instead (title-bar entry for this dialog).
class CustomsCheckDialog extends ConsumerStatefulWidget {
  /// Optional prefill (e.g. names from the open shopping list).
  final String? initialItemDescription;

  const CustomsCheckDialog({super.key, this.initialItemDescription});

  @override
  ConsumerState<CustomsCheckDialog> createState() => _CustomsCheckDialogState();
}

class _CustomsCheckDialogState extends ConsumerState<CustomsCheckDialog> {
  late final TextEditingController _itemCtrl;
  final _excerptCtrl = TextEditingController();
  String? _offlineReport;
  LlmResult? _llm;
  bool _llmLoading = false;

  @override
  void initState() {
    super.initState();
    final initial = widget.initialItemDescription?.trim() ?? '';
    _itemCtrl = TextEditingController(text: initial);
    if (initial.isNotEmpty) {
      // Auto-run offline pack when opened from the list title bar.
      _offlineReport = CompliancePackService.formatHits(
        CompliancePackService.matchCustomsItem(initial),
      );
    }
  }

  @override
  void dispose() {
    _itemCtrl.dispose();
    _excerptCtrl.dispose();
    super.dispose();
  }

  void _runOffline() {
    final item = _itemCtrl.text.trim();
    if (item.isEmpty) return;
    setState(() {
      _offlineReport = CompliancePackService.formatHits(
        CompliancePackService.matchCustomsItem(item),
      );
    });
  }

  Future<void> _runLlm() async {
    final item = _itemCtrl.text.trim();
    final excerpt = _excerptCtrl.text.trim();
    if (item.isEmpty || excerpt.isEmpty) return;
    setState(() {
      _llmLoading = true;
      _llm = null;
    });
    final boat = await ref.read(activeBoatProvider.future);
    final result = await LlmClientService().complete(
      boat: boat,
      systemPrompt: 'You are a boat provisioning/customs assistant. '
          'Given items being carried and a pasted customs rules excerpt, '
          'assess restrictions. Be concise. Not official customs advice.',
      prompt: jsonEncode(LlmPayloadBuilder.customsQuery(
        itemDescription: item,
        rulesExcerpt: excerpt,
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
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.public, color: Colors.deepPurple, size: 20),
          SizedBox(width: 8),
          Expanded(child: Text('Customs check')),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _itemCtrl,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Item(s) you\'re carrying',
                  helperText: 'e.g. drone, speargun, fresh meat, spirits…',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
              FilledButton(
                onPressed: _runOffline,
                child: const Text('Check offline pack'),
              ),
              if (_offlineReport != null) ...[
                const SizedBox(height: 12),
                Text(_offlineReport!, style: const TextStyle(height: 1.35)),
              ],
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),
              TextField(
                controller: _excerptCtrl,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Customs rules excerpt (optional AI)',
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
                  label: const Text('AI read of excerpt (online)'),
                ),
              if (_llm != null) ...[
                const SizedBox(height: 8),
                Text(
                  _llm!.status == LlmResultStatus.success
                      ? (_llm!.text ?? '')
                      : (_llm!.errorMessage ?? 'AI unavailable'),
                ),
              ],
              const SizedBox(height: 8),
              Text(
                'Not an official customs determination.',
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
