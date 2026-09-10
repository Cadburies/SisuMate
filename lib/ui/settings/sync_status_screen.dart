import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/app_router.dart';
import '../../core/colors.dart';
import '../components/sisu_tile_card.dart';
import '../../core/di.dart';
import '../../services/error_log_service.dart';

/// Pro/dev sync health view (S7) — queue depth, retries, last success/fail.
class SyncStatusScreen extends ConsumerStatefulWidget {
  const SyncStatusScreen({super.key});

  @override
  ConsumerState<SyncStatusScreen> createState() => _SyncStatusScreenState();
}

class _SyncStatusScreenState extends ConsumerState<SyncStatusScreen> {
  Map<String, dynamic>? _status;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final status = await ref.read(syncServiceProvider).getQueueStatus();
      if (!mounted) return;
      setState(() {
        _status = status;
        _loading = false;
      });
    } catch (e, st) {
      unawaited(
          ErrorLogService().logException(e, st, context: 'sync_status_screen: _refresh'));
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _forceFlush() async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(syncServiceProvider).forceProcessQueue();
      await _refresh();
      if (!mounted) return;
      messenger.showSnackBar(
        const SnackBar(content: Text('Queue flush requested')),
      );
    } catch (e, st) {
      unawaited(
          ErrorLogService().logException(e, st, context: 'sync_status_screen: _forceFlush'));
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(content: Text('Flush failed: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isProAsync = ref.watch(isProProvider);

    return Scaffold(
      backgroundColor: SisuColors.getAppBackground(isDark),
      appBar: AppBar(
        title: const Text('Sync Status'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: _loading ? null : _refresh,
          ),
        ],
      ),
      body: isProAsync.when(
        data: (isPro) {
          if (!isPro) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Sync is a Pro feature. Upgrade to see the outbox and force a flush.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: SisuColors.getTextSecondaryColor(isDark),
                  ),
                ),
              ),
            );
          }
          if (_loading && _status == null) {
            return const Center(child: CircularProgressIndicator());
          }
          if (_error != null) {
            return Center(child: Text('Error: $_error'));
          }
          return _StatusBody(
            status: _status!,
            isDark: isDark,
            onFlush: _forceFlush,
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
      ),
    );
  }
}

class _StatusBody extends StatelessWidget {
  final Map<String, dynamic> status;
  final bool isDark;
  final VoidCallback onFlush;

  const _StatusBody({
    required this.status,
    required this.isDark,
    required this.onFlush,
  });

  @override
  Widget build(BuildContext context) {
    final byTable = (status['byTable'] as Map?)?.cast<String, int>() ?? {};
    final byPriority =
        (status['byPriority'] as Map?)?.cast<dynamic, dynamic>() ?? {};
    final online = status['isOnline'] == true;
    final pending = status['totalPending'] as int? ?? 0;
    final conflicts = status['pendingConflicts'] as int? ?? 0;

    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
      children: [
        _Card(
          isDark: isDark,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Connection', style: _heading(isDark)),
              const SizedBox(height: 8),
              _row('Online', online ? 'Yes' : 'No', isDark),
              _row('Pending outbox', '$pending', isDark),
              _row('Pending conflicts', '$conflicts', isDark),
              _row('Last success', _fmtTime(status['lastSuccess']), isDark),
              _row('Last failure', _fmtTime(status['lastFailure']), isDark),
              _row(
                'Processed (session)',
                '${status['processedToday'] ?? 0}',
                isDark,
              ),
              _row(
                'Failed (session)',
                '${status['failedToday'] ?? 0}',
                isDark,
              ),
              _row('Oldest pending', _fmtTime(status['oldestItem']), isDark),
              _row(
                'Delete ops queued',
                '${status['deleteOperations'] ?? 0}',
                isDark,
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _Card(
          isDark: isDark,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('By priority', style: _heading(isDark)),
              const SizedBox(height: 8),
              _row('P0 (normal)', '${byPriority[0] ?? 0}', isDark),
              _row('P1', '${byPriority[1] ?? 0}', isDark),
              _row('P2 (high)', '${byPriority[2] ?? 0}', isDark),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _Card(
          isDark: isDark,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('By table', style: _heading(isDark)),
              const SizedBox(height: 8),
              if (byTable.isEmpty)
                Text(
                  'No pending items',
                  style: TextStyle(
                    color: SisuColors.getTextSecondaryColor(isDark),
                  ),
                )
              else
                ...byTable.entries.map(
                  (e) => _row(e.key, '${e.value}', isDark),
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            FilledButton.icon(
              onPressed: onFlush,
              icon: const Icon(Icons.cloud_upload_outlined),
              label: const Text('Force flush queue'),
            ),
          ],
        ),
      ],
    );
  }

  TextStyle _heading(bool isDark) => TextStyle(
        fontWeight: FontWeight.bold,
        color: SisuColors.getTextPrimaryColor(isDark),
      );

  Widget _row(String label, String value, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: SisuColors.getTextSecondaryColor(isDark),
              ),
            ),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: SisuColors.getTextPrimaryColor(isDark),
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  static String _fmtTime(Object? v) {
    if (v == null) return '—';
    if (v is DateTime) {
      return v.toLocal().toString().split('.').first;
    }
    return v.toString();
  }
}

class _Card extends StatelessWidget {
  final Widget child;
  final bool isDark;
  const _Card({required this.child, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return SisuTileCard(
      color: SisuColors.getTileColor(isDark),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: child,
      ),
    );
  }
}

/// Drawer entry for [SyncStatusScreen].
class SyncStatusDrawerTile extends StatelessWidget {
  const SyncStatusDrawerTile({super.key});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.monitor_heart_outlined),
      title: const Text('Sync Status'),
      subtitle: const Text('Outbox depth & last sync'),
      onTap: () {
        Navigator.of(context).pop();
        context.push(AppRoutes.syncStatus);
      },
    );
  }
}
