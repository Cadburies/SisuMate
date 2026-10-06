import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/app_router.dart';
import '../../models/models.dart';
import '../../providers/shopping_provider.dart' show activeBoatProvider;
import '../../services/llm_client_service.dart';
import '../../services/llm_payload_builder.dart';
import '../../services/maintenance_local_explain.dart';

/// #18 / #208 / #402: "explain this maintenance task".
///
/// The bundled note is shown immediately, with no network and no API key.
/// "Improve with AI" is optional enrichment and is the only path that calls
/// [LlmClientService]. Reached only via the AI badge on a maintenance tile,
/// never blended into Complete/Hide/Delete. The payload is title and
/// description only — never notes or crew data (#16).
class MaintenanceAiExplainerDialog extends ConsumerStatefulWidget {
  final ChecklistItem item;
  const MaintenanceAiExplainerDialog({super.key, required this.item});

  @override
  ConsumerState<MaintenanceAiExplainerDialog> createState() =>
      _MaintenanceAiExplainerDialogState();
}

class _MaintenanceAiExplainerDialogState
    extends ConsumerState<MaintenanceAiExplainerDialog> {
  LlmResult? _llm;
  bool _loading = false;
  late final String _local;

  @override
  void initState() {
    super.initState();
    _local = MaintenanceLocalExplain.explain(
      title: widget.item.title,
      description: widget.item.description,
    );
  }

  Future<void> _improve() async {
    setState(() {
      _loading = true;
      _llm = null;
    });
    final boat = await ref.read(activeBoatProvider.future);
    final payload = LlmPayloadBuilder.maintenanceAlert(
      description: [
        widget.item.title,
        widget.item.description,
      ].where((s) => s != null && s.isNotEmpty).join('. '),
    );
    final result = await LlmClientService().complete(
      boat: boat,
      systemPrompt:
          'You are a boat maintenance assistant. In 2-3 short, '
          'practical sentences, explain why the given maintenance task '
          'matters and what can go wrong if it is skipped. No preamble.',
      prompt: jsonEncode(payload),
    );
    if (mounted) {
      setState(() {
        _loading = false;
        _llm = result;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final llm = _llm;
    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.auto_awesome, color: Colors.deepPurple, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'AI: ${widget.item.title}',
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
              Text(_local),
              if (_loading)
                const Padding(
                  padding: EdgeInsets.only(top: 16),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (llm != null) ...[
                const SizedBox(height: 12),
                _LlmView(result: llm),
              ],
            ],
          ),
        ),
      ),
      actions: [
        if (llm?.status == LlmResultStatus.noKeyConfigured)
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.push(AppRoutes.settings);
            },
            child: const Text('Go to Settings'),
          ),
        TextButton(
          onPressed: _loading ? null : _improve,
          child: const Text('Improve with AI (online)'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }
}

class _LlmView extends StatelessWidget {
  final LlmResult result;
  const _LlmView({required this.result});

  @override
  Widget build(BuildContext context) {
    if (result.status == LlmResultStatus.success) {
      return Text(result.text ?? '');
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          Icons.info_outline,
          size: 18,
          color: Theme.of(context).colorScheme.error,
        ),
        const SizedBox(width: 8),
        Expanded(child: Text(result.errorMessage ?? 'Something went wrong.')),
      ],
    );
  }
}
