import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/app_router.dart';
import '../../models/models.dart';
import '../../providers/shopping_provider.dart' show activeBoatProvider;
import '../../services/llm_client_service.dart';
import '../../services/llm_payload_builder.dart';

/// #18 (first LLM product use) / #208 (AI must be visibly separate from
/// offline logic): "explain this maintenance alert" — an online, BYOK LLM
/// feature reached only via the distinct AI badge on a maintenance tile
/// (`maintenance_items_screen.dart`), never blended into the item's normal
/// offline Complete/Hide/Delete actions (`ItemDetailShell`'s `DetailAction`
/// bar). Payload is built through `LlmPayloadBuilder.maintenanceAlert` —
/// title/description only, never notes or crew data (#16).
class MaintenanceAiExplainerDialog extends ConsumerStatefulWidget {
  final ChecklistItem item;
  const MaintenanceAiExplainerDialog({super.key, required this.item});

  @override
  ConsumerState<MaintenanceAiExplainerDialog> createState() =>
      _MaintenanceAiExplainerDialogState();
}

class _MaintenanceAiExplainerDialogState
    extends ConsumerState<MaintenanceAiExplainerDialog> {
  LlmResult? _result;

  @override
  void initState() {
    super.initState();
    _explain();
  }

  Future<void> _explain() async {
    final boat = await ref.read(activeBoatProvider.future);
    final payload = LlmPayloadBuilder.maintenanceAlert(
      description: [widget.item.title, widget.item.description]
          .where((s) => s != null && s.isNotEmpty)
          .join('. '),
    );
    final result = await LlmClientService().complete(
      boat: boat,
      systemPrompt: 'You are a boat maintenance assistant. In 2-3 short, '
          'practical sentences, explain why the given maintenance task '
          'matters and what can go wrong if it is skipped. No preamble.',
      prompt: jsonEncode(payload),
    );
    if (mounted) setState(() => _result = result);
  }

  @override
  Widget build(BuildContext context) {
    final result = _result;
    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.auto_awesome, color: Colors.deepPurple, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text('AI: ${widget.item.title}', overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: result == null
            ? const SizedBox(
                height: 80,
                child: Center(child: CircularProgressIndicator()),
              )
            : _ResultView(result: result),
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
    if (result.status == LlmResultStatus.success) {
      return Text(result.text ?? '');
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.info_outline,
            size: 18, color: Theme.of(context).colorScheme.error),
        const SizedBox(width: 8),
        Expanded(
          child: Text(result.errorMessage ?? 'Something went wrong.'),
        ),
      ],
    );
  }
}
