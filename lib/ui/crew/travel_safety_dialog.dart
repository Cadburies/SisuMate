import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/app_router.dart';
import '../../providers/shopping_provider.dart' show activeBoatProvider;
import '../../services/llm_client_service.dart';
import '../../services/llm_payload_builder.dart';

/// #224 (built on #223's grounded search): visa/entry-safety briefing for a
/// destination country, given the nationalities on board. Reached only via
/// the distinct AI badge on `crew_screen.dart` (#208 separation — never
/// blended into crew's offline add/edit/share actions). Payload is
/// destination + nationalities only (`LlmPayloadBuilder.travelSafetyQuery`)
/// — no passport upload path exists anywhere in this feature, deliberately.
class TravelSafetyDialog extends ConsumerStatefulWidget {
  const TravelSafetyDialog({super.key});

  @override
  ConsumerState<TravelSafetyDialog> createState() =>
      _TravelSafetyDialogState();
}

class _TravelSafetyDialogState extends ConsumerState<TravelSafetyDialog> {
  final _countryCtrl = TextEditingController();
  final _nationalitiesCtrl = TextEditingController();
  LlmResult? _result;
  bool _loading = false;

  @override
  void dispose() {
    _countryCtrl.dispose();
    _nationalitiesCtrl.dispose();
    super.dispose();
  }

  Future<void> _ask() async {
    final country = _countryCtrl.text.trim();
    final nationalities = _nationalitiesCtrl.text
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
    if (country.isEmpty || nationalities.isEmpty) return;

    setState(() {
      _loading = true;
      _result = null;
    });

    final boat = await ref.read(activeBoatProvider.future);
    final payload = LlmPayloadBuilder.travelSafetyQuery(
      destinationCountry: country,
      nationalities: nationalities,
    );
    final result = await LlmClientService().completeWithSearch(
      boat: boat,
      systemPrompt: 'You are a sailing crew travel-safety assistant. Using '
          'current, live sources, tell the user for each listed nationality '
          'whether a visa is needed to enter the given country, and give a '
          'brief current safety picture (civil unrest, disease alerts, and '
          'any recent reports of theft targeting boats/cruisers in that '
          'region). Be concise and cite what you find. End with a short '
          'reminder to confirm with official government/embassy sources '
          'before travel — this is AI-assisted research, not an official '
          'determination.',
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
            child: Text('AI: Travel & entry safety',
                overflow: TextOverflow.ellipsis),
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
                controller: _countryCtrl,
                decoration:
                    const InputDecoration(labelText: 'Destination country'),
                enabled: !_loading,
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _nationalitiesCtrl,
                decoration: const InputDecoration(
                  labelText: 'Crew nationalities (comma-separated)',
                  helperText: 'Nationality only — never enter passport '
                      'numbers or other passport details.',
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
        if (result?.status == LlmResultStatus.noKeyConfigured ||
            result?.status == LlmResultStatus.groundedSearchUnsupported)
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
        if (result.citations.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text('Sources', style: Theme.of(context).textTheme.labelMedium),
          const SizedBox(height: 4),
          for (final c in result.citations)
            InkWell(
              onTap: () => launchUrl(Uri.parse(c.url),
                  mode: LaunchMode.externalApplication),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Text(
                  c.title ?? c.url,
                  style: const TextStyle(
                      color: Colors.blue, decoration: TextDecoration.underline),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
        ],
      ],
    );
  }
}
