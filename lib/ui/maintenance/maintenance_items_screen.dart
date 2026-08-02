import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../components/title_tile.dart';
import '../components/checklist_item_tile.dart';
import '../components/native_ad_widget.dart';
import '../components/ad_slots.dart';
import '../components/smart_image.dart';
import '../components/add_checklist_item_dialog.dart';

import '../../providers/checklist_provider.dart';
import '../../providers/package_info_provider.dart';
import '../../services/revenuecat_service.dart';
import '../../services/admob_service.dart';
import '../../services/error_log_service.dart';
import '../../services/import_service.dart';
import '../components/import_export.dart';
import '../../core/di.dart';
import '../../core/colors.dart';
import '../../models/models.dart';

/// Dedicated screen for displaying maintenance checklist items for a specific group
/// Shows Title Tile with group name and contains only that group's items
class MaintenanceItemsScreen extends ConsumerStatefulWidget {
  final ChecklistGroup group;

  const MaintenanceItemsScreen({
    super.key,
    required this.group,
  });

  @override
  ConsumerState<MaintenanceItemsScreen> createState() => _MaintenanceItemsScreenState();
}

class _MaintenanceItemsScreenState extends ConsumerState<MaintenanceItemsScreen> {
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
    final asyncItems = ref.watch(checklistItemsProvider(widget.group.supabaseId));
    final isProAsync = ref.watch(isProProvider);
    final isPro = isProAsync.value ?? false;
    final currentItems = asyncItems.asData?.value ?? const <ChecklistItem>[];
    final showHidden =
        ref.watch(userSettingsProvider).asData?.value?.showHiddenItems ?? false;

    return Scaffold(
      key: _scaffoldKey,
      body: SafeArea(
        child: Column(
          children: [
            // Title Tile with group title
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
                      fileBaseName: 'sisu_maintenance',
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
                    return const Center(child: Text('No items in this maintenance checklist'));
                  }

                  // Filter items based on search and show settings
                  final filteredItems = items.where((item) {
                    // Search filter
                    if (_searchQuery.isNotEmpty) {
                      final query = _searchQuery.toLowerCase();
                      if (!item.title.toLowerCase().contains(query) &&
                          (item.description?.toLowerCase().contains(query) != true)) {
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
                  final adSlots = _adSlotCache(filteredItems.length);
                  final total = filteredItems.length + adSlots.length;
                  final List<Widget> widgets = [];
                  for (int i = 0; i < total; i++) {
                    if (isNativeAdSlot(i, adSlots)) {
                      widgets.add(
                          const NativeAdWidget(contextHint: 'maintenance'));
                      continue;
                    }
                    final item =
                        filteredItems[nativeAdContentIndex(i, adSlots)];
                    widgets.add(
                      ChecklistItemTile(
                        item: item,
                        groupName: widget.group.title,
                        fallbackIcon: Icons.build,
                        onComplete: isPro
                            ? () => _toggleComplete(item)
                            : _proGatedComplete,
                        onHide: () => _toggleHide(item),
                        onUnhide: () => _unhideItem(item),
                        onTap: () => _showMaintenanceItemDialog(item),
                      ),
                    );
                  }

                  return ListView(
                    padding: const EdgeInsets.only(bottom: 80), // Safe zone for Android navigation buttons
                    children: widgets,
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('Error loading maintenance items: $e')),
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
          itemNoun: 'maintenance item',
        ),
        tooltip: isPro ? 'Add maintenance item' : 'Upgrade to Pro',
        child: Icon(isPro ? Icons.add : Icons.lock_outline),
      ),
      endDrawer: _buildEndDrawer(),
    );
  }

  void _showMaintenanceItemDialog(ChecklistItem item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(item.title),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (item.assetName != null || item.userPhotoUrl != null || item.userPhotoPath != null)
                Container(
                  width: double.maxFinite,
                  height: 200,
                  margin: const EdgeInsets.only(bottom: 16),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: SmartImage(
                      assetName: item.assetName,
                      userPhotoUrl: item.userPhotoUrl,
                      userPhotoPath: item.userPhotoPath,
                      itemName: item.title,
                      groupName: widget.group.title,
                      fit: BoxFit.cover,
                      customFallback: Container(
                        color: Colors.grey[300],
                        child: const Icon(
                          Icons.build,
                          color: Colors.grey,
                          size: 48,
                        ),
                      ),
                    ),
                  ),
                ),
              if (item.description != null) ...[
                const Text(
                  'Description:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(item.description!),
                const SizedBox(height: 16),
              ],
              Row(
                children: [
                  Icon(
                    item.isCompleted ? Icons.check_circle : Icons.radio_button_unchecked,
                    color: item.isCompleted ? SisuColors.completedBackground : SisuColors.incompleteBackground,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    item.isCompleted ? 'Completed' : 'Not Completed',
                    style: TextStyle(
                      color: item.isCompleted ? SisuColors.completedBackground : SisuColors.incompleteBackground,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          Consumer(
            builder: (context, ref, child) {
              final isProAsync = ref.watch(isProProvider);
              return isProAsync.when(
                data: (isPro) => ElevatedButton(
                  onPressed: isPro
                      ? () {
                          Navigator.pop(context);
                          _toggleComplete(item);
                        }
                      : () async {
                          Navigator.pop(context);
                          // Show interstitial ad first, then upgrade prompt
                          final adMobService = AdMobService();
                          adMobService.createInterstitialAd(); // idempotent; usually preloaded
                          await adMobService.awaitInterstitialReady();
                          await adMobService.showInterstitialAdIfAllowed();

                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Text(
                                  'Completing maintenance items requires Sisu Pro',
                                ),
                                action: SnackBarAction(
                                  label: 'Upgrade',
                                  onPressed: () => RevenueCatService().showPaywall(context),
                                ),
                              ),
                            );
                          }
                        },
                  child: Text(item.isCompleted ? 'Mark Incomplete' : 'Mark Complete'),
                ),
                loading: () => const ElevatedButton(
                  onPressed: null,
                  child: Text('Loading...'),
                ),
                error: (e, _) => const ElevatedButton(
                  onPressed: null,
                  child: Text('Error'),
                ),
              );
            },
          ),
        ],
      ),
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
                  Text(
                    'Filters & Options',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
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
                  hintText: 'Search maintenance items...',
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
                      final repository =
                          ref.read(userSettingsRepositoryProvider);
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
              subtitle: const Text('Restore original checklists'),
              onTap: () => _handleFactoryReset(context),
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
                    onTap: isPro ? null : () => RevenueCatService().showPaywall(context),
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
                    subtitle: Text(user != null ? 'Signed in as ${user.email}' : 'Sync data (Pro only)'),
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
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    loading: () => const Text(
                      'Loading...',
                      style: TextStyle(color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
                    error: (e, _) => Text(
                      'Error: $e',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey,
                      ),
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

  void _handleFactoryReset(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset to Factory Defaults'),
        content: const Text(
          'Are you sure you want to reset all maintenance checklists to factory defaults?\n\n'
          'This will delete all custom items and restore the original checklists.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(context);
              final repository = ref.read(checklistRepositoryProvider);
              await repository.resetToFactoryDefaults('maintenance');
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Maintenance checklists reset to factory defaults')),
                );
              }
            },
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }

  void _showSignInDialog(BuildContext context, WidgetRef ref) {
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    String? errorMessage;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Sign In'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (errorMessage != null) ...[
                Text(
                  errorMessage!,
                  style: const TextStyle(color: Colors.red),
                ),
                const SizedBox(height: 8),
              ],
              TextField(
                controller: emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: passwordController,
                decoration: const InputDecoration(
                  labelText: 'Password',
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
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
                final password = passwordController.text.trim();
                if (email.isEmpty || password.isEmpty) {
                  setState(() {
                    errorMessage = 'Please enter email and password';
                  });
                  return;
                }

                try {
                  await ref.read(authServiceProvider).signIn(email, password);
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Signed in successfully')),
                    );
                  }
                } catch (e, st) {
                  unawaited(ErrorLogService()
                      .logException(e, st, context: 'maintenance_items_screen: signIn'));
                  setState(() {
                    errorMessage = e.toString();
                  });
                }
              },
              child: const Text('Sign In'),
            ),
          ],
        ),
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: 'Sisu Mate',
      applicationVersion: '1.0.0',
      applicationIcon: const Icon(Icons.sailing),
      children: [
        const Text(
          'Sisu Mate is a marine maintenance app for managing checklists and schedules.',
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: () {
            // Open website or privacy policy
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Opening website...')),
            );
          },
          child: const Text('Privacy Policy & Terms'),
        ),
      ],
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
        content: const Text('Completing maintenance items requires Sisu Pro'),
        action: SnackBarAction(
          label: 'Upgrade',
          onPressed: () => RevenueCatService().showPaywall(context),
        ),
      ),
    );
  }
}
