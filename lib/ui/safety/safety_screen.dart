import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../components/title_tile.dart';
import '../components/common_drawer.dart';
import '../components/group_grid.dart';
import '../components/main_list_tile.dart';
import '../../core/app_router.dart';
import '../../core/di.dart';
import '../../models/models.dart';
import '../../providers/checklist_provider.dart';

class SafetyScreen extends ConsumerStatefulWidget {
  const SafetyScreen({super.key});

  @override
  ConsumerState<SafetyScreen> createState() => _SafetyScreenState();
}

class _SafetyScreenState extends ConsumerState<SafetyScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  /// Group-level filters (same labels as Checklists main list drawer).
  bool _showCompleted = true;
  bool _showIncomplete = true;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final asyncGroups = ref.watch(checklistGroupsProvider('safety'));
    // #210: one join query for both the completion-state filter below and
    // the item-content search match — replaces the N-per-group
    // checklistItemsProvider watch this screen used to do here (the exact
    // cascade #207 fixed elsewhere; watchItemsForAppType avoids it).
    final itemsByGroup = groupItemsByGroup(
        ref.watch(checklistItemsForAppTypeProvider('safety')));

    return Scaffold(
      body: SafeArea(
        child: Builder(
          builder: (context) => Column(
            children: [
              TitleTile(
                title: 'Safety Briefings',
                onMenuPressed: () => Scaffold.of(context).openEndDrawer(),
              ),
              MainListSearchBar(
                controller: _searchController,
                hintText: 'Search briefings...',
                onChanged: (v) => setState(() => _searchQuery = v),
              ),
              Expanded(
                child: asyncGroups.when(
                  data: (groups) {
                    if (groups.isEmpty) {
                      return const Center(
                        child: Text(
                          'No safety briefings available.\n(Run Reset Database in Settings if missing)',
                          textAlign: TextAlign.center,
                        ),
                      );
                    }
                    final matchHints = <String, String>{};
                    final filtered = groups.where((g) {
                      final items = itemsByGroup[g.supabaseId] ??
                          const <ChecklistItem>[];
                      final result = matchGroupSearch(
                        group: g,
                        query: _searchQuery,
                        itemsInGroup: items,
                      );
                      if (!result.matches) return false;
                      if (result.matchedItemText != null) {
                        matchHints[g.supabaseId] = result.matchedItemText!;
                      }
                      // Group completion from live item stream (same as tile badge).
                      final visible = items.where((i) => !i.isHidden).toList();
                      if (visible.isEmpty) return true;
                      final allDone =
                          visible.every((i) => i.isCompleted);
                      if (allDone && !_showCompleted) return false;
                      if (!allDone && !_showIncomplete) return false;
                      return true;
                    }).toList();
                    if (filtered.isEmpty) {
                      return const Center(child: Text('No matching briefings'));
                    }
                    return GroupGrid(
                      groups: filtered,
                      icon: Icons.health_and_safety,
                      iconColor: Colors.red,
                      countNoun: 'points',
                      matchHints: matchHints,
                      onTap: (group) => context.push(
                        AppRoutes.safetyItems,
                        extra: group,
                      ),
                    );
                  },
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, _) =>
                      Center(child: Text('Error loading briefings: $e')),
                ),
              ),
            ],
          ),
        ),
      ),
      endDrawer: _buildEndDrawer(),
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
                  subtitle: const Text('Briefings with every point done'),
                  value: _showCompleted,
                  onChanged: (value) {
                    setState(() => _showCompleted = value);
                  },
                ),
                SwitchListTile(
                  title: const Text('Show Incomplete Items'),
                  subtitle: const Text('Briefings still in progress'),
                  value: _showIncomplete,
                  onChanged: (value) {
                    setState(() => _showIncomplete = value);
                  },
                ),
                Consumer(
                  builder: (context, ref, child) {
                    final settingsAsync = ref.watch(userSettingsProvider);
                    return settingsAsync.when(
                      data: (settings) => SwitchListTile(
                        title: const Text('Show Hidden Items'),
                        subtitle: const Text(
                            'Display soft-deleted points inside briefings'),
                        value: settings?.showHiddenItems ?? false,
                        onChanged: (value) async {
                          final updated = (settings ?? UserSettings())
                            ..showHiddenItems = value;
                          await ref
                              .read(userSettingsRepositoryProvider)
                              .updateSettings(updated);
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
