import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../providers/package_info_provider.dart';
import '../../providers/shopping_provider.dart';
import '../../core/app_router.dart';
import '../../core/di.dart';
import '../../core/factory_reset.dart';
import '../../services/error_log_service.dart';
import '../../services/revenuecat_service.dart';
import '../conflicts/conflict_resolution_screen.dart';
import '../settings/sync_status_screen.dart';

/// Reusable Account Section for drawers
class AccountSection extends ConsumerWidget {
  const AccountSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Consumer(
      builder: (context, ref, child) {
        final userAsync = ref.watch(authStateProvider);
        return userAsync.when(
          data: (user) {
            if (user == null) {
              return Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.sailing),
                    title: const Text('Boat account'),
                    subtitle: const Text('Create or sign in to sync (Pro)'),
                    onTap: () => context.go(AppRoutes.accountSetup),
                  ),
                  ListTile(
                    leading: const Icon(Icons.group_add),
                    title: const Text('Join a boat'),
                    subtitle: const Text('Enter a share code from your captain'),
                    onTap: () => context.go(AppRoutes.joinBoat),
                  ),
                ],
              );
            }
            final anon = user.isAnonymous;
            return Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.person),
                  title: Text(anon ? 'Crew member' : (user.email ?? 'Signed In')),
                  subtitle: Text(anon ? 'Joined a shared boat' : 'Signed In'),
                ),
                if (!anon)
                  ListTile(
                    leading: const Icon(Icons.ios_share),
                    title: const Text('Share this boat'),
                    subtitle: const Text('Show the crew join code'),
                    onTap: () => _showShareCode(context, ref),
                  ),
                // Hidden developer console — only for the developer account;
                // the admin_* RPCs re-verify server-side.
                if (ref.read(authServiceProvider).isDeveloper)
                  ListTile(
                    leading: const Icon(Icons.admin_panel_settings),
                    title: const Text('Developer'),
                    subtitle: const Text('Subs, usage & stale-data purge'),
                    onTap: () => context.push(AppRoutes.admin),
                  ),
                if (anon)
                  ListTile(
                    leading: const Icon(Icons.group_add),
                    title: const Text('Join another boat'),
                    onTap: () => context.go(AppRoutes.joinBoat),
                  ),
                ListTile(
                  leading: const Icon(Icons.logout),
                  title: const Text('Sign Out'),
                  onTap: () => ref.read(authServiceProvider).signOut(),
                ),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, s) => ListTile(
            title: const Text('Auth Error'),
            subtitle: Text(e.toString()),
          ),
        );
      },
    );
  }

  Future<void> _showShareCode(BuildContext context, WidgetRef ref) async {
    final boat = await ref.read(activeBoatProvider.future);
    if (!context.mounted) return;
    if (boat == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No active boat to share.')),
      );
      return;
    }
    String? code;
    try {
      code = await ref.read(authServiceProvider).fetchBoatShareCode(boat.supabaseId);
    } catch (e) {
      // fall through to the "unavailable" message
      unawaited(ErrorLogService()
          .logWarning('fetchBoatShareCode failed: $e', context: 'common_drawer: _showShareCode'));
    }
    final senderName = ref.read(authServiceProvider).displayName;
    if (!context.mounted) return;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Share “${boat.name}”'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Give this code to your crew so they can join this boat:'),
            const SizedBox(height: 16),
            SelectableText(
              code ?? 'Unavailable offline',
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                letterSpacing: 4,
              ),
            ),
            if (code != null) ...[
              const SizedBox(height: 12),
              Text(
                'Keep it private — anyone with it can view and edit this boat.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ],
        ),
        actions: [
          if (code != null)
            TextButton.icon(
              icon: const Icon(Icons.copy),
              label: const Text('Copy'),
              onPressed: () {
                Clipboard.setData(ClipboardData(text: code!));
                Navigator.pop(context);
              },
            ),
          if (code != null)
            TextButton.icon(
              icon: const Icon(Icons.share),
              label: const Text('Share'),
              onPressed: () {
                Navigator.pop(context);
                // Chat/social (e.g. WhatsApp): send just the code, easy to paste.
                Share.share(code!);
              },
            ),
          if (code != null)
            TextButton.icon(
              icon: const Icon(Icons.email_outlined),
              label: const Text('Email'),
              onPressed: () {
                Navigator.pop(context);
                _emailBoatCode(boat.name, code!, senderName);
              },
            ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  /// Opens the email composer with a warm, warning-forward invite. Plain-text
  /// mail can't bold, so the code sits alone on its own prominent line.
  Future<void> _emailBoatCode(
      String boatName, String code, String? senderName) async {
    final subject = 'Share $boatName code';
    final signoff = (senderName != null && senderName.isNotEmpty)
        ? '\n$senderName'
        : '';
    final body = 'Hi,\n\n'
        'I\'m inviting you to join my boat "$boatName" on Sisu Mate.\n\n'
        'Please keep this code private: anyone who has it can view AND edit '
        'this boat\'s checklists, logs and lists on their own device, and their '
        'changes sync to everyone. Only share it with trusted crew.\n\n'
        'Your boat code:\n\n'
        '$code\n\n'
        'In Sisu Mate, choose "Join a boat" and enter it.\n\n'
        'Thank you & warm regards,$signoff';
    final uri = Uri.parse(
        'mailto:?subject=${Uri.encodeComponent(subject)}'
        '&body=${Uri.encodeComponent(body)}');
    await launchUrl(uri);
  }
}

/// Reusable Data Management Section for drawers
class DataManagementSection extends ConsumerWidget {
  const DataManagementSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        ListTile(
          leading: const Icon(Icons.sync),
          title: const Text('Synchronise'),
          subtitle: const Text('Update recipe ingredient counts'),
          onTap: () => _handleSync(context, ref),
        ),
        const ConflictsDrawerTile(),
        const SyncStatusDrawerTile(),
        ListTile(
          leading: const Icon(Icons.refresh),
          title: const Text('Reset to Factory'),
          subtitle: const Text('Restore original checklists'),
          onTap: () => _handleFactoryReset(context, ref),
        ),
      ],
    );
  }

  Future<void> _handleSync(BuildContext context, WidgetRef ref) async {
    try {
      final syncFn = ref.read(syncIngredientCountsProvider);
      await syncFn();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Recipe counts updated')),
        );
      }
    } catch (e, st) {
      unawaited(
          ErrorLogService().logException(e, st, context: 'common_drawer: _handleSync'));
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Sync failed: $e')));
      }
    }
  }

  Future<void> _handleFactoryReset(BuildContext context, WidgetRef ref) async {
    // Stronger warning when the boat is synced (Pro): the reset also wipes the
    // cloud copy, which propagates to any crew devices sharing this boat.
    final guid = await ref.read(boatEnrollmentServiceProvider).currentGuid();
    final isSynced = guid != null &&
        guid.isNotEmpty &&
        ref.read(authServiceProvider).currentUser != null;
    if (!context.mounted) return;

    final message = isSynced
        ? 'This restores factory content on this device AND wipes this boat’s '
            'data in the cloud — so it also disappears from any crew devices '
            'sharing this boat. The boat and its join code stay; all lists, '
            'logs and entries are erased. This cannot be undone. Are you sure?'
        : 'This will reset the database to its initial factory state, deleting '
            'all user data. This action cannot be undone. Are you sure?';

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Factory Reset'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                await _performReset(ref);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Database reset to factory state'),
                    ),
                  );
                }
              },
              child: const Text('Reset', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  /// RESET-SYNC: for an enrolled boat, wipe BOTH local Drift AND the boat's
  /// Supabase content, then reseed and re-adopt the SAME GUID (crew stay linked).
  /// A never-enrolled (Free) boat just does the plain local reset.
  Future<void> _performReset(WidgetRef ref) async {
    final enrollment = ref.read(boatEnrollmentServiceProvider);
    final auth = ref.read(authServiceProvider);
    final guid = await enrollment.currentGuid();

    String? boatName;
    if (guid != null && guid.isNotEmpty) {
      boatName = (await ref.read(boatRepositoryProvider).getBoatById(guid))?.name;
      if (auth.currentUser != null) {
        await ref.read(syncServiceProvider).wipeRemoteBoatContent(guid);
      }
    }

    await ref.read(databaseServiceProvider).factoryReset();
    // Always refresh FutureProviders that may hold pre-wipe rows (TEST29).
    invalidateAfterFactoryReset(ref);

    if (guid != null && guid.isNotEmpty) {
      await enrollment.enroll(
          name: boatName ?? 'My Boat', ownerId: auth.currentUser?.id);
      final settings = await ref.read(userSettingsProvider.future);
      if (settings != null) {
        settings.activeBoatSupabaseId = guid;
        await ref.read(userSettingsRepositoryProvider).updateSettings(settings);
      }
      // Re-invalidate after re-stamping the enrolled boat id.
      invalidateAfterFactoryReset(ref);
    }
  }
}

/// Reusable Pro Upgrade Section for drawers
class ProUpgradeSection extends ConsumerWidget {
  const ProUpgradeSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Consumer(
      builder: (context, ref, child) {
        final isProAsync = ref.watch(isProProvider);
        return isProAsync.when(
          data: (isPro) => ListTile(
            leading: const Icon(Icons.star),
            title: const Text('Upgrade to Pro'),
            subtitle: const Text('Unlock all features'),
            enabled: !isPro,
            onTap: isPro
                ? null
                : () => RevenueCatService().showPaywall(context),
          ),
          loading: () => const ListTile(
            title: Text('Loading...'),
            leading: CircularProgressIndicator(),
          ),
          error: (e, _) => ListTile(
            title: const Text('Error'),
            subtitle: Text(e.toString()),
          ),
        );
      },
    );
  }
}

/// Reusable About Section for drawers
class AboutSection extends ConsumerWidget {
  const AboutSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListTile(
      leading: const Icon(Icons.info),
      title: const Text('About'),
      subtitle: const Text('Version info & links'),
      onTap: () => _showAboutDialog(context, ref),
    );
  }

  void _showAboutDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('About Sisu Mate'),
        content: Consumer(
          builder: (context, ref, child) {
            final versionAsync = ref.watch(appVersionProvider);
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                versionAsync.when(
                  data: (version) => Text('Version: $version'),
                  loading: () => const Text('Version: Loading...'),
                  error: (e, _) => const Text('Version: Unknown'),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Professional offshore boating suite with 12 integrated apps.',
                ),
                const SizedBox(height: 8),
                const Text(
                  'Visit Sailing Sisu on YouTube for tutorials and tips.',
                ),
                const SizedBox(height: 8),
                const Text('Privacy Policy & Terms available in Settings.'),
              ],
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

/// Reusable Drawer Header
class DrawerHeaderWidget extends StatelessWidget {
  final String title;

  const DrawerHeaderWidget({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
      child: Row(
        children: [
          const Icon(Icons.menu),
          const SizedBox(width: 8),
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

/// Reusable Section Header
class SectionHeader extends StatelessWidget {
  final String title;

  const SectionHeader({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
          color: Theme.of(context).primaryColor,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

/// Reusable Footer with app name and version
class DrawerFooter extends ConsumerWidget {
  const DrawerFooter({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Consumer(
        builder: (context, ref, child) {
          final appNameVersionAsync = ref.watch(appNameVersionProvider);
          return appNameVersionAsync.when(
            data: (appNameVersion) => Text(
              appNameVersion,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            loading: () => const Text(
              'Loading...',
              style: TextStyle(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            error: (e, _) => Text(
              'Sisu Mate',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          );
        },
      ),
    );
  }
}
