import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/app_router.dart';
import '../../models/models.dart';
import '../../providers/shopping_provider.dart' show activeBoatProvider;
import '../../services/llm_client_service.dart';
import '../../services/llm_payload_builder.dart';

enum _Phase { input, parsing, error }

/// Extracted as a top-level, directly-testable pure function rather than
/// private dialog state — #220's acceptance criterion is specifically that
/// well-formed/partial/malformed LLM JSON all degrade gracefully, which is
/// easiest to prove with a plain unit test, no widget/network involved.
///
/// Malformed/partial JSON degrades gracefully: missing fields just stay
/// null (blank in the review form), and text that isn't valid JSON at all
/// still returns an (empty) draft rather than crashing or blocking the
/// user from reaching the normal entry form.
CaptainLogEntry parseAiLogEntryResponse(String raw) {
  var text = raw.trim();
  if (text.startsWith('```')) {
    text = text
        .replaceFirst(RegExp(r'^```[a-zA-Z]*\n?'), '')
        .replaceFirst(RegExp(r'```\s*$'), '')
        .trim();
  }
  try {
    final decoded = jsonDecode(text);
    if (decoded is! Map) return CaptainLogEntry();
    String? asNonEmptyString(Object? v) {
      if (v is! String) return null;
      final t = v.trim();
      return t.isEmpty ? null : t;
    }

    return CaptainLogEntry()
      ..weather = asNonEmptyString(decoded['weather'])
      ..windSpeedKt = (decoded['windSpeedKt'] is num)
          ? (decoded['windSpeedKt'] as num).round()
          : null
      ..windDir = asNonEmptyString(decoded['windDir'])
      ..notes = asNonEmptyString(decoded['notes']);
  } catch (_) {
    return CaptainLogEntry();
  }
}

/// #220 / #208: freeform Captain's Log entry parsing — the AI-assisted
/// "text box first" step reached via a distinct purple `auto_awesome` FAB
/// next to Captain's Log's normal "Add Entry" FAB (`logbook_screen.dart`).
/// Never auto-saves: on a successful parse this dialog pops with a draft
/// `CaptainLogEntry`, which the caller feeds into the normal
/// `AddEditCaptainLogDialog` for the user to review/edit before saving —
/// exactly like any other new entry.
class AiLogEntryParseDialog extends ConsumerStatefulWidget {
  const AiLogEntryParseDialog({super.key});

  @override
  ConsumerState<AiLogEntryParseDialog> createState() =>
      _AiLogEntryParseDialogState();
}

class _AiLogEntryParseDialogState
    extends ConsumerState<AiLogEntryParseDialog> {
  final _textCtrl = TextEditingController();
  _Phase _phase = _Phase.input;
  String? _errorMessage;
  LlmResultStatus? _errorStatus;

  @override
  void dispose() {
    _textCtrl.dispose();
    super.dispose();
  }

  Future<void> _parse() async {
    final freeform = _textCtrl.text.trim();
    if (freeform.isEmpty) return;
    setState(() => _phase = _Phase.parsing);

    final boat = await ref.read(activeBoatProvider.future);
    final payload = LlmPayloadBuilder.parseLogEntryText(freeform);
    final result = await LlmClientService().complete(
      boat: boat,
      systemPrompt:
          'You extract structured fields from a sailor\'s freeform Captain\'s '
          'Log entry. Respond with ONLY a single JSON object, no markdown '
          'code fences, no prose before or after, matching exactly this '
          'shape (use null for anything not mentioned): '
          '{"weather": string or null, "windSpeedKt": number or null, '
          '"windDir": string or null, "notes": string or null}. "notes" '
          'should be a cleaned-up version of the freeform text (events, '
          'sightings, engine/equipment observations) with the weather/wind '
          'facts you extracted separately left in, not stripped out.',
      prompt: jsonEncode(payload),
    );
    if (!mounted) return;

    if (result.status != LlmResultStatus.success) {
      setState(() {
        _phase = _Phase.error;
        _errorStatus = result.status;
        _errorMessage = result.errorMessage;
      });
      return;
    }

    final draft = parseAiLogEntryResponse(result.text ?? '');
    Navigator.of(context).pop(draft);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.auto_awesome, color: Colors.deepPurple, size: 20),
          SizedBox(width: 8),
          Expanded(child: Text('AI: Parse Log Entry')),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: _buildBody(context),
      ),
      actions: _buildActions(context),
    );
  }

  Widget _buildBody(BuildContext context) {
    switch (_phase) {
      case _Phase.input:
        return TextField(
          controller: _textCtrl,
          autofocus: true,
          maxLines: 5,
          decoration: const InputDecoration(
            labelText: 'Describe what happened',
            hintText: 'Motored out past the point around 0800, 12kt SW '
                'breeze, saw dolphins, engine ran a bit rough at first...',
            border: OutlineInputBorder(),
          ),
        );
      case _Phase.parsing:
        return const SizedBox(
          height: 80,
          child: Center(child: CircularProgressIndicator()),
        );
      case _Phase.error:
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.info_outline,
                size: 18, color: Theme.of(context).colorScheme.error),
            const SizedBox(width: 8),
            Expanded(
              child:
                  Text(_errorMessage ?? 'Something went wrong.'),
            ),
          ],
        );
    }
  }

  List<Widget> _buildActions(BuildContext context) {
    switch (_phase) {
      case _Phase.input:
        return [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: _parse,
            child: const Text('Parse'),
          ),
        ];
      case _Phase.parsing:
        return [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ];
      case _Phase.error:
        return [
          if (_errorStatus == LlmResultStatus.noKeyConfigured)
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                context.push(AppRoutes.settings);
              },
              child: const Text('Go to Settings'),
            ),
          TextButton(
            onPressed: () => setState(() => _phase = _Phase.input),
            child: const Text('Back'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ];
    }
  }
}
