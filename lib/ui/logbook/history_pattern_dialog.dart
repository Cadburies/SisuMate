import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/app_router.dart';
import '../../models/models.dart';
import '../../providers/shopping_provider.dart' show activeBoatProvider;
import '../../services/llm_client_service.dart';
import '../../services/llm_payload_builder.dart';

/// Below this many qualifying notes, the LLM has nothing to find a pattern
/// in — asking it anyway would just burn the user's BYOK tokens on "not
/// enough data" restated in prose.
const int _minHistoryEntries = 3;

/// How far back / how many notes to send — keeps the BYOK token bill
/// bounded regardless of how long a boat's history is (#17-adjacent cost
/// discipline, not a privacy filter).
const int _maxHistoryEntries = 40;
const Duration _lookback = Duration(days: 180);

/// #218 / #208: cross-history pattern detection — reasoning over *many*
/// historical free-text notes at once (paraphrased recurring themes, not
/// exact string repeats) is structurally beyond seed data or keyword rules.
/// Reached via a distinct AI action on Captain's Log's title bar, never
/// blended into the log list's own actions. Complements (does not
/// duplicate) #216's risk triage: that reasons over *current* overdue
/// state, this reasons over *historical* notes.
class HistoryPatternDialog extends ConsumerStatefulWidget {
  final List<CaptainLogEntry> logEntries;
  final List<MaintenanceTask> maintenanceTasks;

  const HistoryPatternDialog({
    super.key,
    required this.logEntries,
    required this.maintenanceTasks,
  });

  @override
  ConsumerState<HistoryPatternDialog> createState() =>
      _HistoryPatternDialogState();
}

class _HistoryPatternDialogState extends ConsumerState<HistoryPatternDialog> {
  LlmResult? _result;
  bool _notEnoughHistory = false;

  @override
  void initState() {
    super.initState();
    _detect();
  }

  List<({DateTime date, String source, String text})> _qualifyingEntries() {
    final cutoff = DateTime.now().subtract(_lookback);
    final entries = <({DateTime date, String source, String text})>[];
    for (final log in widget.logEntries) {
      final text = log.notes?.trim();
      if (text == null || text.isEmpty) continue;
      if (log.logDate.isBefore(cutoff)) continue;
      entries.add((date: log.logDate, source: 'log', text: text));
    }
    for (final task in widget.maintenanceTasks) {
      final text = task.notes?.trim();
      if (text == null || text.isEmpty) continue;
      if (task.lastModified.isBefore(cutoff)) continue;
      entries.add((date: task.lastModified, source: 'maintenance', text: text));
    }
    entries.sort((a, b) => b.date.compareTo(a.date));
    return entries.take(_maxHistoryEntries).toList();
  }

  Future<void> _detect() async {
    final entries = _qualifyingEntries();
    if (entries.length < _minHistoryEntries) {
      if (mounted) setState(() => _notEnoughHistory = true);
      return;
    }
    final boat = await ref.read(activeBoatProvider.future);
    final payload = LlmPayloadBuilder.historySnippets(entries: entries);
    final result = await LlmClientService().complete(
      boat: boat,
      systemPrompt:
          'You are a boat maintenance/log pattern spotter. You are given '
          'dated free-text notes from a boat\'s Captain\'s Log and '
          'maintenance history. Look across ALL of them (not just the most '
          'recent) for recurring or paraphrased themes — the same issue '
          'mentioned more than once in different words, not just exact '
          'repeats. List each recurring theme you find with the dates it '
          'appeared. This is NOT a diagnosis — always frame it as a pattern '
          'worth investigating in person, not a conclusion. If nothing '
          'recurs, say so briefly. No preamble.',
      prompt: jsonEncode(payload),
    );
    if (mounted) setState(() => _result = result);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.auto_awesome, color: Colors.deepPurple, size: 20),
          SizedBox(width: 8),
          Expanded(child: Text('AI: Recurring Issues')),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: _buildBody(context),
      ),
      actions: [
        if (_result?.status == LlmResultStatus.noKeyConfigured)
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

  Widget _buildBody(BuildContext context) {
    if (_notEnoughHistory) {
      return const Text(
          'Not enough log or maintenance notes yet to look for patterns — '
          'keep logging and check back later.');
    }
    final result = _result;
    if (result == null) {
      return const SizedBox(
        height: 80,
        child: Center(child: CircularProgressIndicator()),
      );
    }
    return SingleChildScrollView(child: _ResultView(result: result));
  }
}

class _ResultView extends StatelessWidget {
  final LlmResult result;
  const _ResultView({required this.result});

  @override
  Widget build(BuildContext context) {
    if (result.status == LlmResultStatus.success) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(result.text ?? ''),
          const SizedBox(height: 8),
          Text(
            'Not a diagnosis — investigate in person before acting on this.',
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(fontStyle: FontStyle.italic),
          ),
        ],
      );
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
