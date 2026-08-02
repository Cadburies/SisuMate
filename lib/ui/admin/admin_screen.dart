import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/supabase_client.dart';
import '../../services/error_log_service.dart';
import '../components/title_tile.dart';

/// Hidden developer console (STALE-DATA): subscription/usage stats and
/// stale-boat purging. Reached only via the drawer entry that appears for
/// [AuthService.developerEmail]; every RPC re-verifies admin server-side
/// (`app_admins`), so this screen is safe even if navigated to directly.
class AdminScreen extends ConsumerStatefulWidget {
  const AdminScreen({super.key});

  @override
  ConsumerState<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends ConsumerState<AdminScreen> {
  Map<String, dynamic>? _stats;
  List<dynamic> _staleBoats = [];
  int _staleMonths = 12;
  int _graceDays = 7;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final client = SupabaseClientWrapper.instance;
      final stats = await client.rpc('admin_stats');
      final stale = await client
          .rpc('admin_stale_boats', params: {'p_months': _staleMonths});
      setState(() {
        _stats = (stats as Map).cast<String, dynamic>();
        _staleBoats = stale as List<dynamic>;
      });
    } catch (e, st) {
      unawaited(ErrorLogService().logException(e, st, context: 'admin_screen: _load'));
      setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  /// Days remaining in the grace period, or null if never warned. <= 0 means
  /// the grace period has elapsed and it's safe to purge.
  int? _graceRemaining(Map<String, dynamic> b) {
    final warnedAt = b['warnedAt'] as String?;
    if (warnedAt == null) return null;
    final since = DateTime.now().difference(DateTime.parse(warnedAt)).inDays;
    return _graceDays - since;
  }

  /// Composes the warning email in the device's mail app (mailto:) — the
  /// developer reviews and sends it themself, matching the "Share this boat"
  /// email pattern. Only stamps `warnedAt` (via admin_mark_warned) once the
  /// developer confirms they actually sent it.
  Future<void> _warn(Map<String, dynamic> b) async {
    final guid = b['boatGuid'] as String;
    final name = b['boatName'] as String? ?? guid;
    final email = b['ownerEmail'] as String?;
    final lastSeen = b['lastSeenAt'] as String?;
    final monthsInactive = lastSeen == null
        ? 'a long time'
        : '${(DateTime.now().difference(DateTime.parse(lastSeen)).inDays / 30).floor()}+ months';
    final deadline = DateTime.now().add(Duration(days: _graceDays));
    final deadlineStr = '${deadline.year}-${deadline.month.toString().padLeft(2, '0')}-${deadline.day.toString().padLeft(2, '0')}';

    final subject = 'Sisu Mate — action needed for "$name"';
    final body = 'Hi,\n\n'
        'We noticed your boat "$name" on Sisu Mate hasn\'t been active in '
        '$monthsInactive.\n\n'
        'To keep your data in the cloud, please open the Sisu Mate app and '
        'sign in within the next $_graceDays days (by $deadlineStr). If we '
        'don\'t see any activity by then, this boat\'s cloud data (checklists, '
        'logs, recipes and other saved lists) will be permanently deleted from '
        'our servers. Your account itself stays, and you can always start '
        'fresh, but the saved history would be lost.\n\n'
        'If you\'d like to keep everything, simply open the app and sign in — '
        'that\'s all it takes.\n\n'
        'Thank you,\nSisu Mate';

    final uri = Uri(
      scheme: 'mailto',
      path: email ?? '',
      query: 'subject=${Uri.encodeComponent(subject)}&body=${Uri.encodeComponent(body)}',
    );
    await launchUrl(uri);
    if (!mounted) return;

    final sent = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Mark as warned?'),
        content: Text(
          'Did you send the warning email to $email? This records the date so '
          'the console can track the $_graceDays-day grace period.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Not yet'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Yes, sent'),
          ),
        ],
      ),
    );
    if (sent != true) return;

    try {
      await SupabaseClientWrapper.instance
          .rpc('admin_mark_warned', params: {'p_guid': guid});
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('$name marked as warned')));
      _load();
    } catch (e, st) {
      unawaited(ErrorLogService().logException(e, st, context: 'admin_screen: _warn'));
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Failed to record: $e')));
    }
  }

  Future<void> _purge(Map<String, dynamic> boat) async {
    final guid = boat['boatGuid'] as String;
    final name = boat['boatName'] as String? ?? guid;
    final grace = _graceRemaining(boat);
    final graceNote = grace == null
        ? '\n\n⚠ This owner was never warned.'
        : grace > 0
            ? '\n\n⚠ Grace period still has $grace day(s) left.'
            : '\n\nGrace period elapsed — warned ${-grace} day(s) ago.';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Purge “$name”?'),
        content: Text(
          'Permanently deletes this boat\'s cloud data (content, crew '
          'memberships and the boat row). The owner\'s account stays and can '
          're-enroll later. Boat: $guid$graceNote',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Purge', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      final result = await SupabaseClientWrapper.instance
          .rpc('admin_purge_boat', params: {'p_guid': guid});
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
              'Purged $name — ${(result as Map)['contentRowsDeleted']} content rows')));
      _load();
    } catch (e, st) {
      unawaited(ErrorLogService().logException(e, st, context: 'admin_screen: _purge'));
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Purge failed: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const TitleTile(title: 'Developer'),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Text(_error!, textAlign: TextAlign.center),
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _load,
                          child: ListView(
                            padding: const EdgeInsets.all(16),
                            children: [
                              _statsCard(context),
                              const SizedBox(height: 16),
                              _staleCard(context),
                            ],
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statsCard(BuildContext context) {
    final s = _stats ?? {};
    final rows = (s['rows'] as Map?)?.cast<String, dynamic>() ?? {};
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Subscriptions & usage',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _chip('Active subs', s['activeSubs']),
                _chip('Accounts', s['profiles']),
                _chip('Auth users', s['authUsers']),
                _chip('Anonymous crew', s['anonymousUsers']),
                _chip('Boats', s['boats']),
                _chip('Crew links', s['crewMemberships']),
                _chip('Community', s['communityTemplates']),
                _chip('DB size', '${s['dbSizeMb'] ?? '?'} MB'),
              ],
            ),
            const Divider(height: 24),
            Text('Synced rows', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final e in rows.entries) _chip(e.key, e.value),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _staleCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text('Stale boats',
                      style: Theme.of(context).textTheme.titleMedium),
                ),
                DropdownButton<int>(
                  value: _staleMonths,
                  items: const [
                    DropdownMenuItem(value: 6, child: Text('6 mo')),
                    DropdownMenuItem(value: 12, child: Text('12 mo')),
                    DropdownMenuItem(value: 24, child: Text('24 mo')),
                  ],
                  onChanged: (v) {
                    if (v == null) return;
                    setState(() => _staleMonths = v);
                    _load();
                  },
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Owner not subscribed and app unseen for the selected period.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            Row(
              children: [
                const Expanded(child: Text('Grace period after warning: ')),
                DropdownButton<int>(
                  value: _graceDays,
                  items: const [
                    DropdownMenuItem(value: 7, child: Text('7 days')),
                    DropdownMenuItem(value: 14, child: Text('14 days')),
                    DropdownMenuItem(value: 30, child: Text('30 days')),
                  ],
                  onChanged: (v) {
                    if (v == null) return;
                    setState(() => _graceDays = v);
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (_staleBoats.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text('None — everyone is active. 🎉'),
              )
            else
              for (final raw in _staleBoats)
                _staleTile((raw as Map).cast<String, dynamic>()),
          ],
        ),
      ),
    );
  }

  Widget _staleTile(Map<String, dynamic> b) {
    final lastSeen = b['lastSeenAt'] as String?;
    final proUntil = b['proUntil'] as String?;
    final grace = _graceRemaining(b);
    final graceLine = grace == null
        ? 'Not yet warned'
        : grace > 0
            ? 'Warned — $grace day(s) left in grace period'
            : 'Warned — grace period elapsed, safe to purge';
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text('${b['boatName'] ?? '?'} — ${b['ownerEmail'] ?? 'unknown'}'),
      subtitle: Text(
        'Pro until: ${proUntil?.split('T').first ?? 'never'} · '
        'Last seen: ${lastSeen?.split('T').first ?? 'never'} · '
        '${b['contentRows']} rows\n$graceLine',
      ),
      isThreeLine: true,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.mail_outline),
            tooltip: 'Send warning email',
            onPressed: () => _warn(b),
          ),
          IconButton(
            icon: const Icon(Icons.delete_forever, color: Colors.red),
            tooltip: 'Purge cloud data',
            onPressed: () => _purge(b),
          ),
        ],
      ),
    );
  }

  Widget _chip(String label, Object? value) =>
      Chip(label: Text('$label: ${value ?? '?'}'));
}
