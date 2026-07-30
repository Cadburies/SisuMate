import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../components/title_tile.dart';
import '../components/common_drawer.dart';
import '../components/banner_ad_widget.dart';
import '../../core/app_router.dart';
import '../../core/di.dart';
import '../../core/theme.dart';
import '../../core/colors.dart';
import '../../core/units.dart';
import '../../models/models.dart';
import '../../providers/shopping_provider.dart';
import '../../services/suggestion_engine.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final suggestions = ref.watch(boatSuggestionsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: Builder(
          builder: (context) => Column(
            children: [
              // Title Tile at the top
              TitleTile(
                title: 'Sisu Mate',
                onMenuPressed: () => Scaffold.of(context).openEndDrawer(),
              ),
              if (suggestions.isNotEmpty)
                _SuggestionsBanner(suggestions: suggestions, isDark: isDark),
              Expanded(
                child: GridView.count(
                  crossAxisCount: 3,
                  padding: const EdgeInsets.all(12),
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  children: [
                    // ── Row 1: daily-use provisioning ────────────────
                    _AppTile(
                      title: 'Shopping',
                      icon: Icons.shopping_cart,
                      color: Colors.green,
                      onTap: () => context.push(AppRoutes.shopping),
                    ),
                    _AppTile(
                      title: 'Cocktails',
                      icon: Icons.local_bar,
                      color: Colors.deepPurple,
                      onTap: () => context.push(AppRoutes.cocktails),
                    ),
                    _AppTile(
                      title: 'Chef',
                      icon: Icons.restaurant_menu,
                      color: Colors.amber,
                      onTap: () => context.push(AppRoutes.chef),
                    ),
                    // ── Row 2: safety & operational checklists ────────
                    _AppTile(
                      title: 'Safety',
                      icon: Icons.health_and_safety,
                      color: Colors.red,
                      onTap: () => context.push(AppRoutes.safety),
                    ),
                    _AppTile(
                      title: 'Checklists',
                      icon: Icons.checklist,
                      color: Colors.blue,
                      onTap: () => context.push(AppRoutes.checklists),
                    ),
                    _AppTile(
                      title: 'Maintenance',
                      icon: Icons.build,
                      color: Colors.orange,
                      onTap: () => context.push(AppRoutes.maintenance),
                    ),
                    // ── Row 3: voyage logging & monitoring ────────────
                    _AppTile(
                      title: "Captain's Log",
                      icon: Icons.book,
                      color: Colors.brown,
                      onTap: () => context.push(AppRoutes.logbook),
                    ),
                    _AppTile(
                      title: 'Fuel & Water',
                      icon: Icons.local_gas_station,
                      color: Colors.deepOrange,
                      onTap: () => context.push(AppRoutes.fuel),
                    ),
                    _AppTile(
                      title: 'Inventory',
                      icon: Icons.inventory,
                      color: Colors.teal,
                      onTap: () => context.push(AppRoutes.inventory),
                    ),
                    // ── Row 4: crew, admin & community ───────────────
                    _AppTile(
                      title: 'Crew & Contacts',
                      icon: Icons.people,
                      color: Colors.purple,
                      onTap: () => context.push(AppRoutes.crew),
                    ),
                    _AppTile(
                      title: 'Documents',
                      icon: Icons.folder,
                      color: Colors.grey,
                      onTap: () => context.push(AppRoutes.documents),
                    ),
                    _AppTile(
                      title: 'Community',
                      icon: Icons.people_outline,
                      color: Colors.cyan,
                      onTap: () => context.push(AppRoutes.community),
                    ),
                    // ── Row 5: passage & entertainment ────────────────
                    _AppTile(
                      title: 'Weather',
                      icon: Icons.wb_cloudy,
                      color: Colors.lightBlue,
                      onTap: () => context.push(AppRoutes.weather),
                    ),
                    _AppTile(
                      title: 'Games',
                      icon: Icons.casino,
                      color: Colors.indigo,
                      onTap: () => context.push(AppRoutes.games),
                    ),
                  ],
                ),
              ),
              // Banner ad at the bottom — never overlaps content
              const BannerAdWidget(),
            ],
          ),
        ),
      ),
      endDrawer: Builder(builder: (context) => _buildEndDrawer(context)),
    );
  }

  Widget _buildEndDrawer(BuildContext context) {
    return Drawer(
      child: Consumer(
        builder: (context, ref, _) {
          return Column(
            children: [
              const DrawerHeaderWidget(title: 'Sisu Mate'),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      const SectionHeader(title: 'Account'),
                      const AccountSection(),
                      const Divider(),
                      const SectionHeader(title: 'Boats'),
                      Consumer(
                        builder: (context, ref, child) {
                          final boatsAsync = ref.watch(boatsProvider);
                          final activeBoatAsync = ref.watch(activeBoatProvider);
                          final isProAsync = ref.watch(isProProvider);

                          return isProAsync.when(
                            data: (isPro) => boatsAsync.when(
                              data: (boats) {
                                return Column(
                                  children: [
                                    activeBoatAsync.when(
                                      data: (activeBoat) => ListTile(
                                        title: const Text('Active Boat'),
                                        subtitle: Text(
                                            activeBoat?.name ?? 'No boat selected'),
                                        trailing: PopupMenuButton<Boat>(
                                          onSelected: (boat) async {
                                            final userSettings = await ref
                                                .read(userSettingsProvider.future);
                                            if (userSettings != null) {
                                              userSettings.activeBoatSupabaseId =
                                                  boat.supabaseId;
                                              await ref
                                                  .read(
                                                      userSettingsRepositoryProvider)
                                                  .updateSettings(userSettings);
                                              ref.invalidate(userSettingsProvider);
                                              ref.invalidate(activeBoatProvider);
                                            }
                                          },
                                          itemBuilder: (context) => boats
                                              .map((boat) => PopupMenuItem(
                                                    value: boat,
                                                    child: Text(boat.name),
                                                  ))
                                              .toList(),
                                          child: const Icon(Icons.arrow_drop_down),
                                        ),
                                      ),
                                      loading: () => const ListTile(
                                        title: Text('Active Boat'),
                                        subtitle: Text('Loading...'),
                                      ),
                                      error: (e, _) => ListTile(
                                        title: const Text('Active Boat'),
                                        subtitle: Text('Error: $e'),
                                      ),
                                    ),
                                    if (isPro) ...[
                                      ListTile(
                                        title: const Text('Manage Boats'),
                                        subtitle: const Text(
                                          'Add, edit, or delete boats',
                                        ),
                                        trailing: const Icon(
                                          Icons.directions_boat,
                                        ),
                                        onTap: () {
                                          Navigator.pop(context);
                                          context.push(AppRoutes.boats);
                                        },
                                      ),
                                    ] else if (boats.length <= 1) ...[
                                      const ListTile(
                                        title: Text('Boat Management'),
                                        subtitle: Text(
                                          'Upgrade to Pro for multiple boats',
                                        ),
                                        trailing: Icon(Icons.lock),
                                      ),
                                    ],
                                  ],
                                );
                              },
                              loading: () => const ListTile(
                                title: Text('Active Boat'),
                                subtitle: Text('Loading boats...'),
                              ),
                              error: (e, _) => ListTile(
                                title: const Text('Active Boat'),
                                subtitle: Text('Error loading boats: $e'),
                              ),
                            ),
                            loading: () => const ListTile(
                              title: Text('Active Boat'),
                              subtitle: Text('Loading subscription...'),
                            ),
                            error: (e, _) => ListTile(
                              title: const Text('Active Boat'),
                              subtitle: Text('Error: $e'),
                            ),
                          );
                        },
                      ),
                      const Divider(),
                      // Appearance — the theme toggle lives only here, in the
                      // main-screen drawer (theme.md §1). Default is dark.
                      const SectionHeader(title: 'Appearance'),
                      SwitchListTile(
                        secondary: Icon(
                          ref.watch(themeModeProvider) == ThemeMode.dark
                              ? Icons.dark_mode
                              : Icons.light_mode,
                        ),
                        title: const Text('Dark theme'),
                        value: ref.watch(themeModeProvider) == ThemeMode.dark,
                        onChanged: (isDark) {
                          final notifier = ref.read(themeModeProvider.notifier);
                          isDark
                              ? notifier.setDarkTheme()
                              : notifier.setLightTheme();
                        },
                      ),
                      SwitchListTile(
                        secondary: Icon(
                          ref.watch(unitSystemProvider) == UnitSystem.imperial
                              ? Icons.straighten
                              : Icons.science_outlined,
                        ),
                        title: const Text('Imperial units'),
                        subtitle: Text(
                          ref.watch(unitSystemProvider) == UnitSystem.imperial
                              ? 'Showing fl oz, cups, gal, °F…'
                              : 'Showing ml, g, L, °C… (storage is always metric)',
                        ),
                        value:
                            ref.watch(unitSystemProvider) == UnitSystem.imperial,
                        onChanged: (useImperial) {
                          final notifier = ref.read(unitSystemProvider.notifier);
                          useImperial
                              ? notifier.setImperial()
                              : notifier.setMetric();
                        },
                      ),
                      const Divider(),
                      const SectionHeader(title: 'Data Management'),
                      const DataManagementSection(),
                      const Divider(),
                      ListTile(
                        leading: const Icon(Icons.settings),
                        title: const Text('Settings'),
                        onTap: () {
                          Navigator.pop(context);
                          context.push(AppRoutes.settings);
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const DrawerFooter(),
            ],
          );
        },
      ),
    );
  }
}

/// S4 home strip — offline-rules maintenance / weather suggestions.
class _SuggestionsBanner extends StatelessWidget {
  final List<BoatSuggestion> suggestions;
  final bool isDark;
  const _SuggestionsBanner({required this.suggestions, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final top = suggestions.take(3).toList();
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 4),
      child: Card(
        elevation: 2,
        color: SisuColors.getTileColor(isDark),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Suggestions',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: SisuColors.getTextPrimaryColor(isDark),
                ),
              ),
              const SizedBox(height: 6),
              for (final s in top) ...[
                InkWell(
                  onTap: s.routePath == null
                      ? null
                      : () => context.push(s.routePath!),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          s.severity == SuggestionSeverity.urgent
                              ? Icons.warning_amber_rounded
                              : s.severity == SuggestionSeverity.watch
                                  ? Icons.schedule
                                  : Icons.lightbulb_outline,
                          size: 18,
                          color: s.severity == SuggestionSeverity.urgent
                              ? SisuColors.notAvailableText
                              : SisuColors.completedText,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                s.title,
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                  color:
                                      SisuColors.getTextPrimaryColor(isDark),
                                ),
                              ),
                              Text(
                                s.detail,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: SisuColors.getTextSecondaryColor(
                                      isDark),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _AppTile extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _AppTile({
    required this.title,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Card(
      elevation: 4,
      color: SisuColors.getHomeTile(isDark),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 36, color: color),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Text(
                title,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                  color: SisuColors.getTextPrimaryColor(isDark),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
