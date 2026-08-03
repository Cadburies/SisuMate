import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/app_router.dart';
import '../../services/llm_client_service.dart';

/// Shared shape behind #222/#226/#227/#228: the user pastes an excerpt of
/// their own document (warranty terms, certification card, insurance
/// policy, customs rules) alongside a short description of the situation,
/// and an LLM reasons over exactly that pasted text — never a stored
/// `Document`'s content, since no OCR/text-extraction pipeline exists.
/// Extracted once a third near-identical dialog (#227) was about to be
/// copy-pasted from #222/#226, per #227's own note.
///
/// Each caller supplies its own field labels/helpers, system prompt +
/// payload (via [onAsk]), and disclaimer wording — this widget only owns
/// the two-field form, loading/result states, and the "no key configured →
/// Go to Settings" affordance common to all four.
class PastedExcerptCheckDialog extends ConsumerStatefulWidget {
  final String title;
  final String descriptionLabel;
  final String descriptionHelper;
  final String excerptLabel;
  final String excerptHelper;
  final String disclaimer;
  final Future<LlmResult> Function(String description, String excerpt) onAsk;

  const PastedExcerptCheckDialog({
    super.key,
    required this.title,
    required this.descriptionLabel,
    required this.descriptionHelper,
    required this.excerptLabel,
    required this.excerptHelper,
    required this.disclaimer,
    required this.onAsk,
  });

  @override
  ConsumerState<PastedExcerptCheckDialog> createState() =>
      _PastedExcerptCheckDialogState();
}

class _PastedExcerptCheckDialogState
    extends ConsumerState<PastedExcerptCheckDialog> {
  final _descriptionCtrl = TextEditingController();
  final _excerptCtrl = TextEditingController();
  LlmResult? _result;
  bool _loading = false;

  @override
  void dispose() {
    _descriptionCtrl.dispose();
    _excerptCtrl.dispose();
    super.dispose();
  }

  Future<void> _ask() async {
    final description = _descriptionCtrl.text.trim();
    final excerpt = _excerptCtrl.text.trim();
    if (description.isEmpty || excerpt.isEmpty) return;

    setState(() {
      _loading = true;
      _result = null;
    });

    final result = await widget.onAsk(description, excerpt);
    if (mounted) setState(() { _loading = false; _result = result; });
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
            child: Text(widget.title, overflow: TextOverflow.ellipsis),
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
                controller: _descriptionCtrl,
                maxLines: 3,
                minLines: 2,
                decoration: InputDecoration(
                  labelText: widget.descriptionLabel,
                  helperText: widget.descriptionHelper,
                  helperMaxLines: 2,
                ),
                enabled: !_loading,
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _excerptCtrl,
                maxLines: 8,
                minLines: 4,
                decoration: InputDecoration(
                  labelText: widget.excerptLabel,
                  helperText: widget.excerptHelper,
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
                _ResultView(result: result, disclaimer: widget.disclaimer),
            ],
          ),
        ),
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
  final String disclaimer;
  const _ResultView({required this.result, required this.disclaimer});

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
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.info_outline,
                size: 16, color: Theme.of(context).colorScheme.secondary),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                disclaimer,
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(fontStyle: FontStyle.italic),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
