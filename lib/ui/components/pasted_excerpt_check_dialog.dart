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
/// Each caller supplies its own field labels/helpers, the offline reading
/// ([onLocal]), the optional LLM call ([onAsk]), and disclaimer wording.
/// This widget owns the two-field form. The offline reading runs with no
/// key; "Improve with AI" is the only path that calls the LLM, and the
/// "no key configured → Go to Settings" affordance stays on that path.
class PastedExcerptCheckDialog extends ConsumerStatefulWidget {
  final String title;
  final String descriptionLabel;
  final String descriptionHelper;
  final String excerptLabel;
  final String excerptHelper;
  final String disclaimer;
  final String Function(String description, String excerpt) onLocal;
  final Future<LlmResult> Function(String description, String excerpt) onAsk;

  const PastedExcerptCheckDialog({
    super.key,
    required this.title,
    required this.descriptionLabel,
    required this.descriptionHelper,
    required this.excerptLabel,
    required this.excerptHelper,
    required this.disclaimer,
    required this.onLocal,
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
  String? _localReport;
  LlmResult? _llm;
  bool _loading = false;

  @override
  void dispose() {
    _descriptionCtrl.dispose();
    _excerptCtrl.dispose();
    super.dispose();
  }

  (String, String)? _fields() {
    final description = _descriptionCtrl.text.trim();
    final excerpt = _excerptCtrl.text.trim();
    if (description.isEmpty || excerpt.isEmpty) return null;
    return (description, excerpt);
  }

  void _checkOffline() {
    final fields = _fields();
    if (fields == null) return;
    setState(() {
      _localReport = widget.onLocal(fields.$1, fields.$2);
    });
  }

  Future<void> _improve() async {
    final fields = _fields();
    if (fields == null) return;

    setState(() {
      _localReport = widget.onLocal(fields.$1, fields.$2);
      _loading = true;
      _llm = null;
    });

    final result = await widget.onAsk(fields.$1, fields.$2);
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
    final local = _localReport;
    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.auto_awesome, color: Colors.deepPurple, size: 20),
          const SizedBox(width: 8),
          Expanded(child: Text(widget.title, overflow: TextOverflow.ellipsis)),
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
              if (local != null)
                _LocalView(text: local, disclaimer: widget.disclaimer),
              if (_loading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (llm != null) ...[
                if (local != null) const SizedBox(height: 12),
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
          onPressed: _loading ? null : _checkOffline,
          child: const Text('Check offline'),
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

class _LocalView extends StatelessWidget {
  final String text;
  final String disclaimer;
  const _LocalView({required this.text, required this.disclaimer});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(text),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.info_outline,
              size: 16,
              color: Theme.of(context).colorScheme.secondary,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                disclaimer,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(fontStyle: FontStyle.italic),
              ),
            ),
          ],
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
