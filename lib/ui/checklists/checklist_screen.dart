import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../components/title_tile.dart';
import '../components/common_drawer.dart';
import '../components/group_grid.dart';
import '../components/main_list_tile.dart';
import '../../providers/checklist_provider.dart';
import '../../providers/shopping_provider.dart';
import '../../core/app_router.dart';
import '../../core/di.dart';
import '../../models/models.dart';
import '../../services/revenuecat_service.dart';

class ChecklistScreen extends ConsumerStatefulWidget {
  const ChecklistScreen({super.key});

  @override
  ConsumerState<ChecklistScreen> createState() => _ChecklistScreenState();
}

class _ChecklistScreenState extends ConsumerState<ChecklistScreen> {
  final TextEditingController _searchController = TextEditingController();
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
    final asyncGroups = ref.watch(checklistGroupsProvider('checklist'));

    return Scaffold(
      body: SafeArea(
        child: Builder(
          builder: (context) => Column(
            children: [
              TitleTile(
                title: 'Checklists',
                onMenuPressed: () => Scaffold.of(context).openEndDrawer(),
              ),
              MainListSearchBar(
                controller: _searchController,
                hintText: 'Search checklists...',
                onChanged: (v) => setState(() => _searchQuery = v),
              ),
              Expanded(
                child: asyncGroups.when(
                  data: (groups) {
                    if (groups.isEmpty) {
                      return const Center(child: Text('No checklists available'));
                    }

                    final filteredGroups = groups.where((group) {
                      if (_searchQuery.isNotEmpty) {
                        return group.title
                            .toLowerCase()
                            .contains(_searchQuery.toLowerCase());
                      }
                      return true;
                    }).toList();

                    if (filteredGroups.isEmpty) {
                      return const Center(child: Text('No matching checklists'));
                    }

                    return GroupGrid(
                      groups: filteredGroups,
                      icon: Icons.checklist,
                      iconColor: Colors.blue,
                      countNoun: 'items',
                      onTap: (group) => context.push(
                        AppRoutes.checklistItems,
                        extra: group,
                      ),
                    );
                  },
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, _) =>
                      Center(child: Text('Error loading checklists: $e')),
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: _buildFab(),
      endDrawer: _buildEndDrawer(),
    );
  }

  Widget _buildFab() {
    final isProAsync = ref.watch(isProProvider);
    return isProAsync.when(
      data: (isPro) => FloatingActionButton(
        onPressed: isPro
            ? () => _showCreateGroupDialog()
            : () => RevenueCatService().showPaywall(context),
        tooltip: isPro ? 'Create custom checklist' : 'Upgrade to Pro',
        child: Icon(isPro ? Icons.add : Icons.lock_outline),
      ),
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
    );
  }

  void _showCreateGroupDialog() {
    final titleController = TextEditingController();
    final messenger = ScaffoldMessenger.of(context);

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('New Checklist'),
        content: TextField(
          controller: titleController,
          decoration: const InputDecoration(
            labelText: 'Checklist name',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
          textCapitalization: TextCapitalization.sentences,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final title = titleController.text.trim();
              if (title.isEmpty) return;
              Navigator.of(dialogContext).pop();

              final activeBoot = await ref.read(activeBoatProvider.future);
              final group = ChecklistGroup()
                ..supabaseId =
                    'custom_${DateTime.now().millisecondsSinceEpoch}'
                ..title = title
                ..appType = 'checklist'
                ..boatSupabaseId = activeBoot?.supabaseId ?? ''
                ..isBundled = false
                ..origin = 'user'
                ..lastModified = DateTime.now().toUtc();

              try {
                await ref.read(checklistRepositoryProvider).createGroup(group);
                ref.invalidate(checklistGroupsProvider);
              } catch (e) {
                messenger.showSnackBar(
                  SnackBar(content: Text('Failed to create checklist: $e')),
                );
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  Widget _buildEndDrawer() {
    return Drawer(
      child: SafeArea(
        child: Consumer(
          builder: (context, ref, child) => SingleChildScrollView(
            child: Column(
              children: [
                DrawerHeaderWidget(title: 'Filters & Menu'),
                const Divider(),
                SwitchListTile(
                  title: const Text('Show Completed Items'),
                  value: _showCompleted,
                  onChanged: (value) {
                    setState(() => _showCompleted = value);
                  },
                ),
                SwitchListTile(
                  title: const Text('Show Incomplete Items'),
                  value: _showIncomplete,
                  onChanged: (value) {
                    setState(() => _showIncomplete = value);
                  },
                ),
                const Divider(),
                SectionHeader(title: 'Account'),
                AccountSection(),
                const Divider(),
                SectionHeader(title: 'Data Management'),
                DataManagementSection(),
                ProUpgradeSection(),
                AboutSection(),
                DrawerFooter(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
