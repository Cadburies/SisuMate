import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../components/title_tile.dart';
import '../components/common_drawer.dart';
import '../components/banner_ad_widget.dart';
import '../components/sisu_tile_card.dart';
import '../../core/app_router.dart';
import '../../core/di.dart';
import '../../core/colors.dart';
import '../../providers/passage_readiness_provider.dart';
import '../../services/suggestion_engine.dart';

/// #278 — session-only hide for home strips (process restart restores them).
/// Does not delete underlying readiness/suggestion data.
class _SessionDismissNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void dismiss() => state = true;
}

final homePassageReadinessDismissedProvider =
    NotifierProvider<_SessionDismissNotifier, bool>(
  _SessionDismissNotifier.new,
);
final homeSuggestionsDismissedProvider =
    NotifierProvider<_SessionDismissNotifier, bool>(
  _SessionDismissNotifier.new,
);

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final suggestions = ref.watch(boatSuggestionsProvider);
    final readiness = ref.watch(passageReadinessProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final readinessDismissed =
        ref.watch(homePassageReadinessDismissedProvider);
    final suggestionsDismissed =
        ref.watch(homeSuggestionsDismissedProvider);

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
              if (!readinessDismissed)
                Dismissible(
                  key: const ValueKey('home_passage_readiness'),
                  direction: DismissDirection.horizontal,
                  onDismissed: (_) {
                    ref
                        .read(homePassageReadinessDismissedProvider.notifier)
                        .dismiss();
                  },
                  background: _homeDismissBackground(isDark, alignEnd: false),
                  secondaryBackground:
                      _homeDismissBackground(isDark, alignEnd: true),
                  child: _PassageReadinessCard(
                    readiness: readiness,
                    isDark: isDark,
                  ),
                ),
              if (suggestions.isNotEmpty && !suggestionsDismissed)
                Dismissible(
                  key: const ValueKey('home_suggestions'),
                  direction: DismissDirection.horizontal,
                  onDismissed: (_) {
                    ref
                        .read(homeSuggestionsDismissedProvider.notifier)
                        .dismiss();
                  },
                  background: _homeDismissBackground(isDark, alignEnd: false),
                  secondaryBackground:
                      _homeDismissBackground(isDark, alignEnd: true),
                  child: _SuggestionsBanner(
                    suggestions: suggestions,
                    isDark: isDark,
                  ),
                ),
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
                    // ── Row 5: passage tools ──────────────────────────
                    _AppTile(
                      title: 'Weather',
                      icon: Icons.wb_cloudy,
                      color: Colors.lightBlue,
                      onTap: () => context.push(AppRoutes.weather),
                    ),
                    _AppTile(
                      title: 'Polar',
                      icon: Icons.radar,
                      color: Colors.cyanAccent,
                      onTap: () => context.push(AppRoutes.polarChart),
                    ),
                    _AppTile(
                      title: 'Anchor Alarm',
                      icon: Icons.anchor,
                      color: Colors.blueGrey,
                      onTap: () => context.push(AppRoutes.anchorAlarm),
                    ),
                    // ── Last: entertainment ───────────────────────────
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
      child: Column(
        children: [
          const DrawerHeaderWidget(title: 'Sisu Mate'),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.settings),
                    title: const Text('Settings'),
                    subtitle: const Text(
                      'Boats, appearance, units, email & sharing',
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      context.push(AppRoutes.settings);
                    },
                  ),
                  const Divider(),
                  const SectionHeader(title: 'Account'),
                  const AccountSection(),
                  const Divider(),
                  const SectionHeader(title: 'Data Management'),
                  const DataManagementSection(),
                  const Divider(),
                  const ProUpgradeSection(),
                  const AboutSection(),
                ],
              ),
            ),
          ),
          const DrawerFooter(),
        ],
      ),
    );
  }
}

Widget _homeDismissBackground(bool isDark, {required bool alignEnd}) {
  return Container(
    alignment: alignEnd ? Alignment.centerRight : Alignment.centerLeft,
    margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
    padding: const EdgeInsets.symmetric(horizontal: 16),
    decoration: BoxDecoration(
      color: SisuColors.hideAction,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Text(
      'Dismiss',
      style: TextStyle(
        color: SisuColors.dialogButtonOnColor,
        fontWeight: FontWeight.w600,
      ),
    ),
  );
}

/// BAI1 — single go/no-go verdict: safety checklist + maintenance overdue +
/// cached weather + fuel/water runway, combined into "Ready" or a short list
/// of things to fix first. Swipe-dismissable for the session (#278).
class _PassageReadinessCard extends StatelessWidget {
  final PassageReadiness readiness;
  final bool isDark;
  const _PassageReadinessCard({required this.readiness, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final ready = readiness.isReady;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      child: SisuTileCard(
        elevation: 2,
        color: ready
            ? SisuColors.getTileColor(isDark)
            : SisuColors.notAvailableBackground.withValues(alpha: 0.18),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                ready ? Icons.check_circle_outline : Icons.error_outline,
                color: ready
                    ? SisuColors.completedText
                    : SisuColors.notAvailableText,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      readiness.headline,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: SisuColors.getTextPrimaryColor(isDark),
                      ),
                    ),
                    for (final b in readiness.blockers)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          '• $b',
                          style: TextStyle(
                            fontSize: 11,
                            color: SisuColors.getTextSecondaryColor(isDark),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// S4 home strip — offline-rules maintenance / weather suggestions.
/// Swipe-dismissable for the session (#278).
class _SuggestionsBanner extends StatelessWidget {
  final List<BoatSuggestion> suggestions;
  final bool isDark;
  const _SuggestionsBanner({required this.suggestions, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final top = suggestions.take(3).toList();
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 4),
      child: SisuTileCard(
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
    return SisuTileCard(
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
