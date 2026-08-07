import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/app_router.dart';
import '../../providers/shopping_provider.dart' show activeBoatProvider;
import '../../services/compliance_pack_service.dart';
import '../../services/llm_client_service.dart';
import '../../services/llm_payload_builder.dart';

/// #226 / #290: safety compliance — offline pack first, optional AI on excerpt.
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
  String? _offlineReport;
  LlmResult? _llm;
  bool _llmLoading = false;

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
        CompliancePackService.matchSafetyItem(item),
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
      systemPrompt: 'You are a boat safety-equipment assistant. Given a '
          'description of a safety item\'s current state and a pasted '
          'excerpt from its service manual or certification card, '
          'assess whether it looks still compliant/in-date. Be concise. '
          'Not a certified inspection.',
      prompt: jsonEncode(LlmPayloadBuilder.safetyComplianceQuery(
        itemDescription: item,
        excerptText: excerpt,
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
          Icon(Icons.health_and_safety, color: Colors.deepPurple, size: 20),
          SizedBox(width: 8),
          Expanded(child: Text('Safety compliance check')),
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
                  labelText: 'Item & current state',
                  helperText: 'e.g. handheld flares, last service 2024, EPIRB…',
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
                  labelText: 'Manual excerpt (optional, for AI)',
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
                  style: const TextStyle(height: 1.35),
                ),
              ],
              const SizedBox(height: 8),
              Text(
                'Offline pack and AI are reminders only — not a certified inspection.',
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
