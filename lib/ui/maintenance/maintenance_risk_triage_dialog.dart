import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/app_router.dart';
import '../../models/models.dart';
import '../../providers/shopping_provider.dart' show activeBoatProvider;
import '../../services/llm_client_service.dart';
import '../../services/llm_payload_builder.dart';
import '../../services/maintenance_risk_scorer.dart';

/// #216 / #289: maintenance risk triage — **local rules first** (#286),
/// optional LLM prose when online. Reached via AI badge on maintenance hours.
class MaintenanceRiskTriageDialog extends ConsumerStatefulWidget {
  final List<MaintenanceTask> tasks;
  const MaintenanceRiskTriageDialog({super.key, required this.tasks});

  @override
  ConsumerState<MaintenanceRiskTriageDialog> createState() =>
      _MaintenanceRiskTriageDialogState();
}

class _MaintenanceRiskTriageDialogState
    extends ConsumerState<MaintenanceRiskTriageDialog> {
  late final String _localReport;
  LlmResult? _llmResult;
  bool _llmLoading = false;

  @override
  void initState() {
    super.initState();
    final ranked = MaintenanceRiskScorer.rank(
      asOf: DateTime.now(),
      tasks: widget.tasks.map((t) => (
            description: t.description,
            intervalHours: t.intervalHours,
            intervalMonths: t.intervalMonths,
            lastDoneHours: t.lastDoneHours,
            lastDoneDate: t.lastDoneDate,
          )),
    );
    _localReport = MaintenanceRiskScorer.formatReport(ranked);
  }

  Future<void> _runLlm() async {
    setState(() {
      _llmLoading = true;
      _llmResult = null;
    });
    final boat = await ref.read(activeBoatProvider.future);
    final payload = LlmPayloadBuilder.maintenanceBacklog(
      asOf: DateTime.now(),
      tasks: widget.tasks.map((t) => (
            description: t.description,
            intervalHours: t.intervalHours,
            intervalMonths: t.intervalMonths,
            lastDoneHours: t.lastDoneHours,
            lastDoneDate: t.lastDoneDate,
          )),
    );
    final result = await LlmClientService().complete(
      boat: boat,
      systemPrompt:
          'You are a boat maintenance risk assessor. You are given the '
          'outstanding maintenance backlog for a boat (description, '
          'interval, and when each task was last done) plus today\'s date. '
          'Rank the items most likely to cause a real breakage or safety '
          'incident if ignored first. For each risky item give 1-2 short, '
          'concrete sentences of failure-mode reasoning (what specifically '
          'can go wrong and when), not just "overdue". If nothing looks '
          'genuinely risky, say so briefly. No preamble.',
      prompt: jsonEncode(payload),
    );
    if (mounted) {
      setState(() {
        _llmResult = result;
        _llmLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final llm = _llmResult;
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.analytics_outlined, color: Colors.deepPurple, size: 20),
          SizedBox(width: 8),
          Expanded(child: Text('Maintenance risk triage')),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _localReport,
                style: const TextStyle(height: 1.35),
              ),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),
              Text(
                'Optional AI narrative (online + API key)',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              if (_llmLoading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (llm == null)
                OutlinedButton.icon(
                  onPressed: _runLlm,
                  icon: const Icon(Icons.auto_awesome, size: 18),
                  label: const Text('Explain with AI'),
                )
              else if (llm.status == LlmResultStatus.success)
                Text(llm.text ?? '', style: const TextStyle(height: 1.35))
              else
                Text(
                  llm.errorMessage ?? 'AI unavailable',
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
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
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }
}
