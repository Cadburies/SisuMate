import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../components/title_tile.dart';
import '../components/common_drawer.dart';
import '../components/group_grid.dart';
import '../components/main_list_tile.dart';
import '../../providers/checklist_provider.dart';
import '../../core/app_router.dart';
import '../../core/di.dart';
import '../../models/models.dart';

class MaintenanceScreen extends ConsumerStatefulWidget {
  const MaintenanceScreen({super.key});

  @override
  ConsumerState<MaintenanceScreen> createState() => _MaintenanceScreenState();
}

class _MaintenanceScreenState extends ConsumerState<MaintenanceScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final asyncGroups = ref.watch(checklistGroupsProvider('maintenance'));

    return Scaffold(
      body: SafeArea(
        child: Builder(
          builder: (context) => Column(
            children: [
              TitleTile(
                title: 'Maintenance',
                onMenuPressed: () => Scaffold.of(context).openEndDrawer(),
              ),
              MainListSearchBar(
                controller: _searchController,
                hintText: 'Search maintenance lists...',
                onChanged: (v) => setState(() => _searchQuery = v),
              ),
              Expanded(
                child: asyncGroups.when(
                  data: (groups) {
                    if (groups.isEmpty) {
                      return const Center(
                          child: Text('No maintenance lists available'));
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
                      return const Center(child: Text('No matching lists'));
                    }

                    return GroupGrid(
                      groups: filteredGroups,
                      icon: Icons.build,
                      iconColor: Colors.orange,
                      countNoun: 'tasks',
                      onTap: (group) => context.push(
                        AppRoutes.maintenanceItems,
                        extra: group,
                      ),
                    );
                  },
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, _) =>
                      Center(child: Text('Error loading maintenance: $e')),
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
          builder: (context, ref, child) => Column(
            children: [
              DrawerHeaderWidget(title: 'Filters & Options'),
              const Divider(),
              Consumer(
                builder: (context, ref, child) {
                  final settingsAsync = ref.watch(userSettingsProvider);
                  return settingsAsync.when(
                    data: (settings) => SwitchListTile(
                      title: const Text('Show Hidden Items'),
                      subtitle: const Text('Display soft-deleted items'),
                      value: settings?.showHiddenItems ?? false,
                      onChanged: (value) async {
                        final updatedSettings =
                            (settings ?? UserSettings())..showHiddenItems = value;
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
              SectionHeader(title: 'Options'),
              DataManagementSection(),
              ProUpgradeSection(),
              AboutSection(),
              const Spacer(),
              DrawerFooter(),
            ],
          ),
        ),
      ),
    );
  }
}
