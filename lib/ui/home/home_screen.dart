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
import '../../providers/home_tile_order_provider.dart';
import '../../providers/passage_readiness_provider.dart';
import '../../services/suggestion_engine.dart';
import 'components/home_module_tile.dart';
import 'home_modules.dart';

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
    final editing = ref.watch(homeTileEditModeProvider);
    final modules = HomeModules.resolve(ref.watch(homeTileOrderProvider));

    return Scaffold(
      body: SafeArea(
        child: Builder(
          builder: (context) => Column(
            children: [
              // Title Tile at the top
              TitleTile(
                title: 'Sisu Mate',
                onMenuPressed: () {
                  ref.read(homeTileEditModeProvider.notifier).exit();
                  Scaffold.of(context).openEndDrawer();
                },
                actionsBuilder: editing
                    ? (iconColor) => [
                          TextButton(
                            key: const ValueKey('home_tile_edit_done'),
                            style: TextButton.styleFrom(
                              foregroundColor: iconColor,
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 8),
                              minimumSize: const Size(40, 40),
                              tapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
                              visualDensity: VisualDensity.compact,
                            ),
                            onPressed: () => ref
                                .read(homeTileEditModeProvider.notifier)
                                .exit(),
                            child: const Text(
                              'Done',
                              style: TextStyle(fontWeight: FontWeight.w700),
                            ),
                          ),
                        ]
                    : null,
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
                    for (var i = 0; i < modules.length; i++)
                      HomeModuleTile(
                        key: ValueKey('home_tile_${modules[i].id}'),
                        module: modules[i],
                        index: i,
                        editing: editing,
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


