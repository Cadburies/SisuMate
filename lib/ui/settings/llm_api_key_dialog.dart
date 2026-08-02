import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/di.dart';
import '../../models/models.dart';
import '../../providers/shopping_provider.dart' show activeBoatProvider;
import '../../services/llm_client_service.dart';
import '../../services/llm_usage_tracker.dart';

/// #215: bring-your-own-key entry dialog. **Local-only by default** — every
/// device (owner or crew) can set its own key, stored only on that device.
/// Only the boat owner additionally sees a "Share with crew" switch — the
/// only thing actually synced (`boats_update` RLS restricts writing the
/// shared boat row to the owner anyway); crew see that switch's state but
/// can't change it.
const _localOnlyReminder =
    'AI features only work when the app is online, this key is valid, and '
    'the account behind it still has tokens/credits remaining. Sisu Mate '
    'never validates, meters, or bills this key — it is used directly from '
    'your device to the provider you choose below. Stored only on this '
    'device by default; nothing is sent to Sisu Mate\'s servers.';

/// #15: local, informational-only usage estimate — never enforced, never
/// synced (even a shared key only reflects *this* device's own usage).
class _UsageSummary extends StatelessWidget {
  const _UsageSummary();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<LlmMonthlyUsage>(
      future: LlmUsageTracker().currentMonth(),
      builder: (context, snapshot) {
        final usage = snapshot.data;
        if (usage == null || usage.totalTokens == 0) {
          return Text(
            'No AI usage recorded on this device yet this month.',
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: Theme.of(context).colorScheme.outline),
          );
        }
        return Text(
          'This device this month: ${usage.totalTokens} tokens '
          '(~\$${usage.estimatedCostUsd.toStringAsFixed(4)} estimated, '
          'published list pricing — check your provider for actual billing).',
          style: Theme.of(context)
              .textTheme
              .bodySmall
              ?.copyWith(color: Theme.of(context).colorScheme.outline),
        );
      },
    );
  }
}

class LlmApiKeyDialog extends ConsumerStatefulWidget {
  final Boat boat;

  /// Whether the signed-in user owns this boat. Only the owner's toggle can
  /// actually change `llmApiKeyShared` (`boats_update` RLS) — for anyone
  /// else the switch is shown but disabled, reflecting the owner's choice.
  final bool isOwner;

  const LlmApiKeyDialog({super.key, required this.boat, required this.isOwner});

  @override
  ConsumerState<LlmApiKeyDialog> createState() => _LlmApiKeyDialogState();
}

class _LlmApiKeyDialogState extends ConsumerState<LlmApiKeyDialog> {
  late LlmProvider _provider;
  late final TextEditingController _keyController;
  late bool _shared;
  bool _obscure = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _provider = LlmProvider.fromId(widget.boat.llmApiKeyProvider) ??
        LlmProvider.openai;
    _keyController = TextEditingController(text: widget.boat.llmApiKey ?? '');
    _shared = widget.boat.llmApiKeyShared;
  }

  @override
  void dispose() {
    _keyController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final trimmed = _keyController.text.trim();
    final boat = widget.boat
      ..llmApiKey = trimmed.isEmpty ? null : trimmed
      ..llmApiKeyProvider = trimmed.isEmpty ? null : _provider.id
      // Non-owners can't change this (switch is disabled) — preserve
      // whatever the last inbound sync set it to, don't reset it to false
      // just because they edited their own local key.
      ..llmApiKeyShared = widget.isOwner ? _shared : widget.boat.llmApiKeyShared;

    final repo = ref.read(boatRepositoryProvider);
    if (widget.isOwner) {
      await repo.updateBoat(boat); // persists + pushes per toJson()'s rules
    } else {
      await repo.upsertLocal(boat); // local-only, never queued for sync
    }
    ref.invalidate(boatsProvider);
    ref.invalidate(activeBoatProvider);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('AI API Key'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.amber.withValues(alpha: 0.4)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.info_outline, size: 18, color: Colors.amber),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(_localOnlyReminder,
                        style: Theme.of(context).textTheme.bodySmall),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<LlmProvider>(
              initialValue: _provider,
              decoration: const InputDecoration(
                labelText: 'Provider',
                border: OutlineInputBorder(),
              ),
              items: LlmProvider.values
                  .map((p) => DropdownMenuItem(value: p, child: Text(p.label)))
                  .toList(),
              onChanged: (p) => setState(() => _provider = p!),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _keyController,
              obscureText: _obscure,
              decoration: InputDecoration(
                labelText: 'API Key',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: Icon(_obscure ? Icons.visibility : Icons.visibility_off),
                  onPressed: () => setState(() => _obscure = !_obscure),
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Leave blank to remove it.',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: Theme.of(context).colorScheme.outline),
            ),
            const SizedBox(height: 12),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: _shared,
              onChanged: widget.isOwner
                  ? (v) => setState(() => _shared = v)
                  : null,
              title: const Text('Share with crew'),
              subtitle: Text(
                widget.isOwner
                    ? (_shared
                        ? 'Synced to every crew member on this boat.'
                        : 'Off — stays only on this device.')
                    : (_shared
                        ? 'The boat owner is sharing a key with the crew.'
                        : 'The boat owner hasn\'t shared a key — only the '
                            'owner can turn this on.'),
              ),
            ),
            const SizedBox(height: 8),
            const _UsageSummary(),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _saving ? null : _save,
          child: _saving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Save'),
        ),
      ],
    );
  }
}
