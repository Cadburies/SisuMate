import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/app_router.dart';
import '../../models/models.dart';
import '../../providers/shopping_provider.dart' show activeBoatProvider;
import '../../services/llm_client_service.dart';
import '../../services/llm_payload_builder.dart';

/// #216 (supersedes the maintenance half of #18) / #208: unlike the single-
/// item "explain this alert" dialog, this sends the user's **whole**
/// outstanding maintenance backlog to the LLM and asks for a risk-ranked,
/// failure-mode-focused triage — reasoning offline rule tables can't do.
/// Reached only via the distinct AI badge on the maintenance hours/service
/// log screen (`maintenance_hours_screen.dart`), never blended into that
/// screen's offline add/edit/delete actions. Payload is built through
/// `LlmPayloadBuilder.maintenanceBacklog` — descriptions + intervals/hours/
/// dates only, never notes or crew names (#16).
class MaintenanceRiskTriageDialog extends ConsumerStatefulWidget {
  final List<MaintenanceTask> tasks;
  const MaintenanceRiskTriageDialog({super.key, required this.tasks});

  @override
  ConsumerState<MaintenanceRiskTriageDialog> createState() =>
      _MaintenanceRiskTriageDialogState();
}

class _MaintenanceRiskTriageDialogState
    extends ConsumerState<MaintenanceRiskTriageDialog> {
  LlmResult? _result;

  @override
  void initState() {
    super.initState();
    _triage();
  }

  Future<void> _triage() async {
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
    if (mounted) setState(() => _result = result);
  }

  @override
  Widget build(BuildContext context) {
    final result = _result;
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.auto_awesome, color: Colors.deepPurple, size: 20),
          SizedBox(width: 8),
          Expanded(child: Text('AI: Maintenance Risk Triage')),
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
      return SingleChildScrollView(child: Text(result.text ?? ''));
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
