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

/// Opens the same [LlmApiKeyDialog] Settings uses, for the active boat.
///
/// Shared by the Settings tile, `/settings?openAiKeys=1`, and shopping's
/// no-key reroute so the user always sees the exact **AI API Keys** copy
/// (paste a key from the provider they already use).
Future<void> showLlmApiKeyDialog(BuildContext context, WidgetRef ref) async {
  final boat = await ref.read(activeBoatProvider.future);
  if (!context.mounted || boat == null) return;
  final currentUserId = ref.read(authStateProvider).value?.id;
  final isOwner = boat.ownerId == null || boat.ownerId == currentUserId;
  await showDialog<void>(
    context: context,
    builder: (_) => LlmApiKeyDialog(boat: boat, isOwner: isOwner),
  );
}

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

/// #211: one key per provider instead of one key total. Every
/// [LlmProvider] gets its own row (key field + owner-only share toggle);
/// a radio button picks which stored provider is currently **active**
/// (used for AI requests) — e.g. switch to Grok once Claude's key runs out
/// of tokens, without re-typing anything.
class LlmApiKeyDialog extends ConsumerStatefulWidget {
  final Boat boat;

  /// Whether the signed-in user owns this boat. Only the owner's toggles can
  /// actually change a given entry's `shared` flag (`boats_update` RLS) —
  /// for anyone else the switch is shown but disabled, reflecting the
  /// owner's choice.
  final bool isOwner;

  const LlmApiKeyDialog({super.key, required this.boat, required this.isOwner});

  @override
  ConsumerState<LlmApiKeyDialog> createState() => _LlmApiKeyDialogState();
}

class _LlmApiKeyDialogState extends ConsumerState<LlmApiKeyDialog> {
  late final Map<String, TextEditingController> _keyControllers;
  late final Map<String, bool> _shared;
  late final Map<String, bool> _originalShared;
  String? _activeProvider;
  bool _obscure = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final entries = {
      for (final e in widget.boat.llmApiKeys) e.provider: e,
    };
    _keyControllers = {
      for (final p in LlmProvider.values)
        p.id: TextEditingController(text: entries[p.id]?.apiKey ?? ''),
    };
    _shared = {
      for (final p in LlmProvider.values) p.id: entries[p.id]?.shared ?? false,
    };
    _originalShared = Map.of(_shared);
    _activeProvider = widget.boat.activeLlmProvider;
  }

  @override
  void dispose() {
    for (final c in _keyControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final entries = <LlmApiKeyEntry>[];
    for (final p in LlmProvider.values) {
      final key = _keyControllers[p.id]!.text.trim();
      if (key.isEmpty) continue;
      entries.add(LlmApiKeyEntry(
        provider: p.id,
        apiKey: key,
        // Non-owners can't change this (switch is disabled) — preserve
        // whatever the last inbound sync set it to, don't reset it just
        // because they edited their own local key.
        shared: widget.isOwner
            ? (_shared[p.id] ?? false)
            : (_originalShared[p.id] ?? false),
      ));
    }
    final activeStillHasKey =
        entries.any((e) => e.provider == _activeProvider);

    final boat = widget.boat
      ..llmApiKeys = entries
      ..activeLlmProvider = activeStillHasKey ? _activeProvider : null;

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
      title: const Text('AI API Keys'),
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
            const SizedBox(height: 12),
            Text(
              'Store a key for each provider you use, and pick which one is '
              'active. Leave a field blank to remove that provider\'s key.',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: Theme.of(context).colorScheme.outline),
            ),
            const SizedBox(height: 12),
            RadioGroup<String>(
              groupValue: _activeProvider,
              onChanged: (v) => setState(() => _activeProvider = v),
              child: Column(
                children: [
                  for (final p in LlmProvider.values) _providerRow(context, p),
                ],
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

  Widget _providerRow(BuildContext context, LlmProvider p) {
    final hasKey = _keyControllers[p.id]!.text.trim().isNotEmpty;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Radio<String>(
                  value: p.id,
                  enabled: hasKey,
                ),
                Expanded(
                  child: Text(p.label,
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                ),
              ],
            ),
            TextField(
              controller: _keyControllers[p.id],
              obscureText: _obscure,
              decoration: InputDecoration(
                labelText: '${p.label} API Key',
                border: const OutlineInputBorder(),
                isDense: true,
                suffixIcon: IconButton(
                  icon: Icon(_obscure ? Icons.visibility : Icons.visibility_off),
                  onPressed: () => setState(() => _obscure = !_obscure),
                ),
              ),
              onChanged: (_) => setState(() {}),
            ),
            SwitchListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              value: _shared[p.id] ?? false,
              onChanged: widget.isOwner
                  ? (v) => setState(() => _shared[p.id] = v)
                  : null,
              title: const Text('Share with crew'),
              subtitle: Text(
                widget.isOwner
                    ? ((_shared[p.id] ?? false)
                        ? 'Synced to every crew member on this boat.'
                        : 'Off — stays only on this device.')
                    : ((_shared[p.id] ?? false)
                        ? 'The boat owner is sharing this key with the crew.'
                        : 'The boat owner hasn\'t shared this key — only '
                            'the owner can turn this on.'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
