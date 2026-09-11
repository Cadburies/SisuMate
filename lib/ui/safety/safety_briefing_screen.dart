import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../components/title_tile.dart';
import '../components/checklist_item_tile.dart';
import '../components/native_ad_widget.dart';
import '../components/ad_slots.dart';
import '../components/add_checklist_item_dialog.dart';
import 'safety_compliance_check_dialog.dart';

import '../checklists/check_page_viewer.dart';
import '../../core/app_router.dart';
import '../../providers/checklist_provider.dart';
import '../../providers/package_info_provider.dart';
import '../../services/revenuecat_service.dart';
import '../../services/admob_service.dart';
import '../../services/error_log_service.dart';
import '../../services/import_service.dart';
import '../components/import_export.dart';
import '../../core/di.dart';
import '../../core/factory_reset.dart';
import '../../models/models.dart';

/// Dedicated screen for displaying safety briefing items for a specific group
/// Shows Title Tile with group name and contains only that group's items
/// Follows the same pattern as ChecklistItemsScreen
class SafetyBriefingItemsScreen extends ConsumerStatefulWidget {
  final ChecklistGroup group;

  const SafetyBriefingItemsScreen({super.key, required this.group});

  @override
  ConsumerState<SafetyBriefingItemsScreen> createState() =>
      _SafetyBriefingItemsScreenState();
}

class _SafetyBriefingItemsScreenState
    extends ConsumerState<SafetyBriefingItemsScreen> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final TextEditingController _searchController = TextEditingController();
  final NativeAdSlotCache _adSlotCache = NativeAdSlotCache();
  String _searchQuery = '';
  bool _showCompleted = true;
  bool _showIncomplete = true;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final asyncItems = ref.watch(
      checklistItemsProvider(widget.group.supabaseId),
    );
    final isProAsync = ref.watch(isProProvider);
    final isPro = isProAsync.value ?? false;
    final currentItems = asyncItems.asData?.value ?? const <ChecklistItem>[];
    // Match checklists: global settings flag drives hidden-item visibility.
    final showHidden =
        ref.watch(userSettingsProvider).asData?.value?.showHiddenItems ?? false;

    return Scaffold(
      key: _scaffoldKey,
      body: SafeArea(
        child: Column(
          children: [
            // Title Tile with group name
            TitleTile(
              title: widget.group.title,
              onMenuPressed: () =>
                  _scaffoldKey.currentState?.openEndDrawer(),
              actionsBuilder: (color) => [
                IconButton(
                  icon: Icon(Icons.import_export, color: color),
                  tooltip: 'Import / Export',
                  onPressed: () => showImportExportSheet(
                    context,
                    ModuleImportExport(
                      kind: ImportService.kindChecklist,
                      label: widget.group.title,
                      fileBaseName: 'sisu_safety',
                      exportCurrent: () async =>
                          ImportService.exportChecklist(currentItems),
                      existingNames: () async =>
                          currentItems.map((e) => e.title).toList(),
                      persist: (batch) async {
                        final repo = ref.read(checklistRepositoryProvider);
                        final existing = await repo
                            .getItemsByGroup(widget.group.supabaseId);
                        var inserted = 0;
                        var updated = 0;
                        for (final item in batch.checklistItems) {
                          item.groupSupabaseId = widget.group.supabaseId;
                          final match = ImportService.matchExisting(
                            existing: existing,
                            incomingId: item.supabaseId,
                            idOf: (e) => e.supabaseId,
                            contentKeyOf: ImportService.contentKeyChecklist,
                            incomingContentKey:
                                ImportService.contentKeyChecklist(item),
                          );
                          if (match != null) {
                            item.supabaseId = match.supabaseId;
                            item.id = match.id;
                            await repo.updateItem(item);
                            updated++;
                          } else {
                            await repo.addItem(item);
                            existing.add(item);
                            inserted++;
                          }
                        }
                        return ImportPersistResult(
                            inserted: inserted, updated: updated);
                      },
                    ),
                    isPro: isPro,
                    onProRequired: () =>
                        RevenueCatService().showPaywall(context),
                              ref: ref,
                  ),
                ),
              ],
            ),
            Expanded(
              child: asyncItems.when(
                data: (items) {
                  if (items.isEmpty) {
                    return const Center(
                      child: Text('No items in this safety briefing'),
                    );
                  }

                  // Filter items based on search and show settings
                  final filteredItems = items.where((item) {
                    // Search filter
                    if (_searchQuery.isNotEmpty) {
                      final query = _searchQuery.toLowerCase();
                      if (!item.title.toLowerCase().contains(query) &&
                          (item.description?.toLowerCase().contains(query) !=
                              true)) {
                        return false;
                      }
                    }

                    // Status filters
                    if (item.isHidden && !showHidden) return false;
                    if (item.isCompleted && !_showCompleted) return false;
                    if (!item.isCompleted && !_showIncomplete) return false;

                    return true;
                  }).toList();

                  // Build list with native tile ads in ≤4 random slots near
                  // the start (user policy 2026-08-01; see ad_slots.dart).
                  // #311 — Pro: no reserved ad indices.
                  final adSlots = _adSlotCache.forList(
                    filteredItems.length,
                    showAds: !isPro,
                  );
                  final total = filteredItems.length + adSlots.length;
                  final List<Widget> widgets = [];
                  for (int i = 0; i < total; i++) {
                    if (isNativeAdSlot(i, adSlots)) {
                      widgets.add(
                          const NativeAdWidget(contextHint: 'safety'));
                      continue;
                    }
                    final item =
                        filteredItems[nativeAdContentIndex(i, adSlots)];
                    widgets.add(
                      Stack(
                        children: [
                          ChecklistItemTile(
                            item: item,
                            groupName: widget.group.title,
                            fallbackIcon: Icons.health_and_safety,
                            onComplete: isPro
                                ? () => _toggleComplete(item)
                                : _proGatedComplete,
                            onHide: () => _toggleHide(item),
                            onUnhide: () => _unhideItem(item),
                            onTap: () => _openViewer(item),
                          ),
                          // #226/#208: AI compliance-check badge — a
                          // visually distinct entry point, never mixed into
                          // the tile's offline Complete/Hide actions above.
                          Positioned(
                            top: 6,
                            right: 6,
                            child: Material(
                              color: Colors.deepPurple,
                              shape: const CircleBorder(),
                              elevation: 2,
                              child: InkWell(
                                customBorder: const CircleBorder(),
                                onTap: () => showDialog(
                                  context: context,
                                  builder: (_) =>
                                      const SafetyComplianceCheckDialog(),
                                ),
                                child: const Padding(
                                  padding: EdgeInsets.all(6),
                                  child: Icon(
                                    Icons.auto_awesome,
                                    size: 16,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView(
                    padding: const EdgeInsets.only(
                      bottom: 80,
                    ), // Safe zone for Android navigation buttons
                    children: widgets,
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(
                  child: Text('Error loading safety briefing items: $e'),
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => showAddCustomChecklistItemDialog(
          context: context,
          ref: ref,
          group: widget.group,
          itemNoun: 'safety item',
        ),
        tooltip: isPro ? 'Add safety item' : 'Upgrade to Pro',
        child: Icon(isPro ? Icons.add : Icons.lock_outline),
      ),
      endDrawer: _buildEndDrawer(),
    );
  }

  Future<void> _toggleComplete(ChecklistItem item) async {
    final repository = ref.read(checklistRepositoryProvider);
    await repository.toggleComplete(item);
  }

  Future<void> _toggleHide(ChecklistItem item) async {
    final repository = ref.read(checklistRepositoryProvider);
    if (item.isHidden) {
      await repository.permanentlyDelete(item);
    } else {
      await repository.hideItem(item);
    }
  }

  Future<void> _unhideItem(ChecklistItem item) async {
    final repository = ref.read(checklistRepositoryProvider);
    await repository.unhideItem(item);
  }

  Widget _buildEndDrawer() {
    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              child: Row(
                children: [
                  const Icon(Icons.filter_list),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Filters & Options',
                      overflow: TextOverflow.ellipsis,
                      style:
                          Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    const Divider(),

                    // Search
                    Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: TextField(
                controller: _searchController,
                decoration: const InputDecoration(
                  hintText: 'Search briefing items...',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
              ),
            ),
            const Divider(),

            // Status Filters
            SwitchListTile(
              title: const Text('Show Completed Items'),
              value: _showCompleted,
              onChanged: (value) {
                setState(() {
                  _showCompleted = value;
                });
              },
            ),
            SwitchListTile(
              title: const Text('Show Incomplete Items'),
              value: _showIncomplete,
              onChanged: (value) {
                setState(() {
                  _showIncomplete = value;
                });
              },
            ),

            // Show Hidden Items Toggle
            Consumer(
              builder: (context, ref, child) {
                final settingsAsync = ref.watch(userSettingsProvider);
                return settingsAsync.when(
                  data: (settings) => SwitchListTile(
                    title: const Text('Show Hidden Items'),
                    subtitle: const Text('Display soft-deleted items'),
                    value: settings?.showHiddenItems ?? false,
                    onChanged: (value) async {
                      final updatedSettings = (settings ?? UserSettings())
                        ..showHiddenItems = value;
                      final repository = ref.read(
                        userSettingsRepositoryProvider,
                      );
                      await repository.updateSettings(updatedSettings);
                      ref.invalidate(userSettingsProvider);
                    },
                  ),
                  loading: () => const ListTile(
                    title: Text('Loading settings...'),
                    leading: CircularProgressIndicator(),
                  ),
                  error: (e, _) => ListTile(
                    title: const Text('Settings Error'),
                    subtitle: Text(e.toString()),
                  ),
                );
              },
            ),
            const Divider(),

            // Universal Options
            ListTile(
              leading: const Icon(Icons.refresh),
              title: const Text('Reset to Factory'),
              subtitle: const Text('Restore original briefings'),
              onTap: () => _handleFactoryReset(context),
            ),
            ListTile(
              leading: const Icon(Icons.done_all),
              title: const Text('Complete All'),
              subtitle: const Text('Mark every item in this list as done'),
              onTap: () => _handleCompleteAll(context),
            ),
            ListTile(
              leading: const Icon(Icons.replay),
              title: const Text('Clear All'),
              subtitle: const Text('Mark every item in this list as not done'),
              onTap: () => _handleUncompleteAll(context),
            ),

            Consumer(
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
            ),

            Consumer(
              builder: (context, ref, child) {
                final userAsync = ref.watch(authStateProvider);
                return userAsync.when(
                  data: (user) => ListTile(
                    leading: Icon(user != null ? Icons.logout : Icons.login),
                    title: Text(user != null ? 'Sign Out' : 'Sign In'),
                    subtitle: Text(
                      user != null
                          ? 'Signed in as ${user.email}'
                          : 'Sync data (Pro only)',
                    ),
                    onTap: user != null
                        ? () => ref.read(authServiceProvider).signOut()
                        : () => _showSignInDialog(context, ref),
                  ),
                  loading: () => const ListTile(
                    title: Text('Loading...'),
                    leading: CircularProgressIndicator(),
                  ),
                  error: (e, _) => ListTile(
                    title: const Text('Auth Error'),
                    subtitle: Text(e.toString()),
                  ),
                );
              },
            ),

            ListTile(
              leading: const Icon(Icons.info),
              title: const Text('About'),
              subtitle: const Text('Version info & links'),
              onTap: () => _showAboutDialog(context),
            ),
                  ],
                ),
              ),
            ),
            // Footer
            Padding(
              padding: const EdgeInsets.all(16),
              child: Consumer(
                builder: (context, ref, child) {
                  final appNameVersionAsync = ref.watch(appNameVersionProvider);
                  return appNameVersionAsync.when(
                    data: (appNameVersion) => Text(
                      appNameVersion,
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
                    loading: () => const Text(
                      'Loading...',
                      style: TextStyle(color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
                    error: (e, _) => Text(
                      'Sisu Mate',
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSignInDialog(BuildContext context, WidgetRef ref) {
    final emailController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign In'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Enter your email to receive a magic link to sign in.'),
            const SizedBox(height: 16),
            TextField(
              controller: emailController,
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final email = emailController.text.trim();
              if (email.isNotEmpty) {
                Navigator.pop(context);
                try {
                  await ref
                      .read(authServiceProvider)
                      .signInWithMagicLink(email);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Magic link sent! Check your email.'),
                      ),
                    );
                  }
                } catch (e, st) {
                  unawaited(ErrorLogService().logException(e, st,
                      context: 'safety_briefing_screen: signInWithMagicLink'));
                  if (context.mounted) {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text('Error: $e')));
                  }
                }
              }
            },
            child: const Text('Send Magic Link'),
          ),
        ],
      ),
    );
  }

  void _handleCompleteAll(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Complete All Items?'),
          content: Text(
            'Mark every item in "${widget.group.title}" as done? This does '
            'not affect hidden items.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                final repository = ref.read(checklistRepositoryProvider);
                await repository.completeAll(widget.group.supabaseId);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('All items marked complete')),
                  );
                }
              },
              child: const Text('Complete All'),
            ),
          ],
        );
      },
    );
  }

  void _handleUncompleteAll(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Clear All Items?'),
          content: Text(
            'Mark every item in "${widget.group.title}" as not done? This '
            'does not affect hidden items.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                final repository = ref.read(checklistRepositoryProvider);
                await repository.uncompleteAll(widget.group.supabaseId);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('All items cleared')),
                  );
                }
              },
              child: const Text('Clear All'),
            ),
          ],
        );
      },
    );
  }

  void _handleFactoryReset(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Factory Reset'),
          content: const Text(
            'This will reset the database to its initial factory state, deleting all user data. This action cannot be undone. Are you sure?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                final dbService = ref.read(databaseServiceProvider);
                await dbService.factoryReset();
                invalidateAfterFactoryReset(ref);
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

  void _showAboutDialog(BuildContext context) {
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

  // Free-tier tap on Complete: interstitial ad + upgrade prompt.
  Future<void> _proGatedComplete() async {
    final adMobService = AdMobService();
    adMobService.createInterstitialAd(); // idempotent; usually preloaded
    await adMobService.awaitInterstitialReady();
    await adMobService.showInterstitialAdIfAllowed();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Marking items complete requires Sisu Pro'),
        action: SnackBarAction(
          label: 'Upgrade',
          onPressed: () => RevenueCatService().showPaywall(context),
        ),
      ),
    );
  }

  Future<void> _openViewer(ChecklistItem item) async {
    final repository = ref.read(checklistRepositoryProvider);
    final allItems = await repository.getItemsByGroup(widget.group.supabaseId);
    if (!mounted) return;
    context.showCheckPageViewer(
      items: allItems,
      initialIndex:
          allItems.indexWhere((i) => i.supabaseId == item.supabaseId),
      groupName: widget.group.title,
      routePath: AppRoutes.safetyItemDetail,
    );
  }
}
