import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/app_router.dart';
import '../../providers/shopping_provider.dart' show activeBoatProvider;
import '../../services/import_service.dart';
import '../../services/llm_client_service.dart';
import '../../services/llm_payload_builder.dart';
import '../../services/messy_import_local_parse.dart';
import 'import_export.dart';

/// Strips a leading/trailing markdown code fence off an LLM response —
/// extracted top-level (same pattern as #220's `parseAiLogEntryResponse`)
/// so the fence-stripping itself is directly unit-testable without a
/// dialog/network round-trip.
String stripJsonCodeFence(String raw) {
  var text = raw.trim();
  if (text.startsWith('```')) {
    text = text
        .replaceFirst(RegExp(r'^```[a-zA-Z]*\n?'), '')
        .replaceFirst(RegExp(r'```\s*$'), '')
        .trim();
  }
  return text;
}

enum _Phase { input, parsing, preview, persisting, error }

/// #221: leftover from #18 — `ImportService` only understands the app's own
/// export JSON shape (IMP1). Sailors often have provisioning lists,
/// maintenance logs, or spares inventories in whatever format another
/// tool/spreadsheet produced; an LLM maps that messy pasted text/CSV into
/// the app's import envelope, and the result is run through the exact same
/// [ImportService.parse] validation a manual JSON paste would get — an LLM
/// mistake can't bypass it. Reached via each module's Import/Export sheet
/// (`import_export.dart`), per #208 separation, one entry per module (the
/// [io.kind] fixes what shape the LLM is asked to produce).
class AiMessyImportDialog extends ConsumerStatefulWidget {
  final ModuleImportExport io;

  const AiMessyImportDialog({super.key, required this.io});

  @override
  ConsumerState<AiMessyImportDialog> createState() =>
      _AiMessyImportDialogState();
}

class _AiMessyImportDialogState extends ConsumerState<AiMessyImportDialog> {
  final _textCtrl = TextEditingController();
  _Phase _phase = _Phase.input;
  String? _errorMessage;
  LlmResultStatus? _errorStatus;
  ImportBatch? _batch;

  @override
  void dispose() {
    _textCtrl.dispose();
    super.dispose();
  }

  Future<void> _parse({bool forceLlm = false}) async {
    final pasted = _textCtrl.text.trim();
    if (pasted.isEmpty) return;
    setState(() => _phase = _Phase.parsing);

    String? boatSupabaseId;
    try {
      boatSupabaseId = (await ref.read(activeBoatProvider.future))?.supabaseId;
    } catch (_) {
      // Offline / no settings — keep placeholder boat id from parse.
    }

    // #302 / #286 — local CSV/line parse first (works offline).
    if (!forceLlm) {
      final localJson = MessyImportLocalParse.tryParseEnvelope(
        pasted,
        kind: widget.io.kind,
      );
      if (localJson != null) {
        try {
          final batch = ImportService.parse(
            localJson,
            boatSupabaseId: boatSupabaseId,
          );
          if (batch.kind == widget.io.kind && batch.count > 0) {
            if (!mounted) return;
            setState(() {
              _phase = _Phase.preview;
              _batch = batch;
            });
            return;
          }
        } on ImportException {
          // Fall through to LLM if online.
        }
      }
    }

    final boat = await ref.read(activeBoatProvider.future);
    final payload = LlmPayloadBuilder.messyImportQuery(pasted);
    final result = await LlmClientService().complete(
      boat: boat,
      systemPrompt: 'You convert messy pasted text or CSV into Sisu Mate\'s '
          'import JSON format for "${widget.io.kind}" items. Respond with '
          'ONLY the JSON object, no markdown code fences, no prose before '
          'or after. Match this exact shape and field names:\n\n'
          '${ImportService.sampleFor(widget.io.kind)}\n\n'
          'Map every distinct item found in the pasted text into one entry '
          'in "items". If a field isn\'t present in the source text, omit '
          'it — never invent a value. If nothing in the text matches, '
          'return {"sisuMateImport": 1, "kind": "${widget.io.kind}", '
          '"items": []}.',
      prompt: jsonEncode(payload),
    );
    if (!mounted) return;

    if (result.status != LlmResultStatus.success) {
      setState(() {
        _phase = _Phase.error;
        _errorStatus = result.status;
        _errorMessage = result.errorMessage ??
            'Could not parse offline (try a CSV or one item per line) '
                'and AI was unavailable.';
      });
      return;
    }

    try {
      final batch = ImportService.parse(
        stripJsonCodeFence(result.text ?? ''),
        boatSupabaseId: boatSupabaseId,
      );
      if (batch.kind != widget.io.kind || batch.count == 0) {
        setState(() {
          _phase = _Phase.error;
          _errorStatus = null;
          _errorMessage = batch.count == 0
              ? 'Nothing recognizable as ${widget.io.label} items was found '
                  'in the pasted text.'
              : 'The AI produced a "${batch.kind}" batch, but this screen '
                  'imports "${widget.io.kind}".';
        });
        return;
      }
      setState(() {
        _phase = _Phase.preview;
        _batch = batch;
      });
    } on ImportException catch (e) {
      setState(() {
        _phase = _Phase.error;
        _errorStatus = null;
        _errorMessage = 'The AI\'s output didn\'t match the expected '
            'format: ${e.display}';
      });
    }
  }

  Future<void> _confirm() async {
    final batch = _batch;
    if (batch == null) return;
    setState(() => _phase = _Phase.persisting);
    try {
      final result = await widget.io.persist(batch);
      if (!mounted) return;
      Navigator.of(context).pop(result);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _phase = _Phase.error;
        _errorStatus = null;
        _errorMessage = 'Import failed: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.auto_awesome, color: Colors.deepPurple, size: 20),
          SizedBox(width: 8),
          Expanded(child: Text('AI: Paste messy list')),
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
          maxLines: 10,
          minLines: 5,
          decoration: InputDecoration(
            labelText: 'Paste your list',
            hintText: 'CSV, one item per line, or a spreadsheet paste. '
                'Parsed offline first; AI is only used for freeform prose.',
            border: const OutlineInputBorder(),
          ),
        );
      case _Phase.parsing:
      case _Phase.persisting:
        return const SizedBox(
          height: 80,
          child: Center(child: CircularProgressIndicator()),
        );
      case _Phase.preview:
        final batch = _batch!;
        final names = ImportService.namesForFuzzyCheck(batch);
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Found ${batch.count} ${widget.io.label} item(s):'),
            const SizedBox(height: 8),
            SizedBox(
              height: 160,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final n in names) Text('• $n'),
                  ],
                ),
              ),
            ),
          ],
        );
      case _Phase.error:
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.info_outline,
                size: 18, color: Theme.of(context).colorScheme.error),
            const SizedBox(width: 8),
            Expanded(child: Text(_errorMessage ?? 'Something went wrong.')),
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
            onPressed: () => _parse(forceLlm: false),
            child: const Text('Parse'),
          ),
        ];
      case _Phase.parsing:
      case _Phase.persisting:
        return [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ];
      case _Phase.preview:
        return [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: _confirm,
            child: const Text('Import'),
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
