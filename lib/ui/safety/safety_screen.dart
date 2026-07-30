import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../components/title_tile.dart';
import '../components/common_drawer.dart';
import '../components/group_grid.dart';
import '../components/main_list_tile.dart';
import '../../core/app_router.dart';
import '../../providers/checklist_provider.dart';

class SafetyScreen extends ConsumerStatefulWidget {
  const SafetyScreen({super.key});

  @override
  ConsumerState<SafetyScreen> createState() => _SafetyScreenState();
}

class _SafetyScreenState extends ConsumerState<SafetyScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final asyncGroups = ref.watch(checklistGroupsProvider('safety'));

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
                    final filtered = groups.where((g) {
                      if (_searchQuery.isEmpty) return true;
                      return g.title
                          .toLowerCase()
                          .contains(_searchQuery.toLowerCase());
                    }).toList();
                    if (filtered.isEmpty) {
                      return const Center(child: Text('No matching briefings'));
                    }
                    return GroupGrid(
                      groups: filtered,
                      icon: Icons.health_and_safety,
                      iconColor: Colors.red,
                      countNoun: 'points',
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
          builder: (context, ref, child) => Column(
            children: [
              DrawerHeaderWidget(title: 'Menu'),
              const Divider(),
              SectionHeader(title: 'Account'),
              AccountSection(),
              const Divider(),
              SectionHeader(title: 'Data Management'),
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
