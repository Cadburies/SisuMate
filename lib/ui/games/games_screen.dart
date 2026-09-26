import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/app_router.dart';
import '../../core/colors.dart';
import '../components/title_tile.dart';
import '../components/common_drawer.dart';
import '../components/banner_ad_widget.dart';
import '../components/sisu_tile_card.dart';

class _IsMultiplayerNotifier extends Notifier<bool> {
  @override
  bool build() => false;
  void set(bool value) => state = value;
}

final isMultiplayerProvider =
    NotifierProvider<_IsMultiplayerNotifier, bool>(_IsMultiplayerNotifier.new);

/// Games hub — theme.md §5 / §8 (main-list chrome + SisuColors).
class GamesScreen extends ConsumerWidget {
  const GamesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isMultiplayer = ref.watch(isMultiplayerProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    void goTo(String gameId) {
      if (isMultiplayer) {
        if (GameCatalog.multiplayerReady.contains(gameId)) {
          context.push(AppRoutes.lobbyGame(gameId));
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Multiplayer coming soon for this game.'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      } else {
        context.push(AppRoutes.playGame(gameId));
      }
    }

    return Scaffold(
      backgroundColor: SisuColors.getAppBackground(isDark),
      endDrawer: Drawer(
        child: ListView(
          children: const [
            DrawerHeaderWidget(title: 'Games'),
            SectionHeader(title: 'Account'),
            AccountSection(),
            SectionHeader(title: 'Data'),
            DataManagementSection(),
            ProUpgradeSection(),
            SectionHeader(title: 'About'),
            AboutSection(),
            DrawerFooter(),
          ],
        ),
      ),
      body: SafeArea(
        child: Stack(
          children: [
            Builder(
              builder: (context) => Column(
                children: [
                  TitleTile(
                    title: 'Games',
                    onMenuPressed: () =>
                        Scaffold.of(context).openEndDrawer(),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 4, 12, 4),
                    child: SisuTileCard(
                      color: SisuColors.getTileColor(isDark),
                      elevation: 2,
                      child: SwitchListTile(
                        title: Text(
                          'Multiplayer Mode',
                          style: TextStyle(
                            color: SisuColors.getTextPrimaryColor(isDark),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: Text(
                          'Host or join over local Wi‑Fi',
                          style: TextStyle(
                            color: SisuColors.getTextSecondaryColor(isDark),
                            fontSize: 12,
                          ),
                        ),
                        value: isMultiplayer,
                        onChanged: (value) {
                          ref.read(isMultiplayerProvider.notifier).set(value);
                        },
                        secondary: Icon(
                          Icons.sports_esports,
                          color: SisuColors.completedBackground,
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GridView.count(
                      crossAxisCount: 2,
                      padding: const EdgeInsets.fromLTRB(12, 8, 12, 72),
                      mainAxisSpacing: 10,
                      crossAxisSpacing: 10,
                      childAspectRatio: 0.92,
                      children: [
                        for (final id in GameCatalog.ids)
                          _GameTile(
                            title: GameCatalog.displayName(id),
                            iconPath: 'assets/games/games/$id/icon.jpg',
                            isMultiplayerReady:
                                GameCatalog.multiplayerReady.contains(id),
                            soloOnlyByDesign:
                                GameCatalog.soloOnlyByDesign.contains(id),
                            multiplayerActive: isMultiplayer,
                            onTap: () => goTo(id),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Align(
              alignment: Alignment.bottomCenter,
              child: BannerAdWidget(),
            ),
          ],
        ),
      ),
    );
  }
}

class _GameTile extends StatelessWidget {
  final String title;
  final String iconPath;
  final VoidCallback onTap;
  final bool isMultiplayerReady;

  /// True when the game is intentionally single-player forever (e.g. Solitaire).
  final bool soloOnlyByDesign;

  /// Whether the hub's multiplayer toggle is currently on. When on, games that
  /// are not [isMultiplayerReady] are shown dimmed with a "Solo only" badge so
  /// the user sees availability at a glance (SUG6/GAME1).
  final bool multiplayerActive;

  const _GameTile({
    required this.title,
    required this.iconPath,
    required this.onTap,
    this.isMultiplayerReady = false,
    this.soloOnlyByDesign = false,
    this.multiplayerActive = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final titleColor = SisuColors.getTextPrimaryColor(isDark);
    final soloOnly = multiplayerActive && !isMultiplayerReady;
    final soloTooltip = soloOnlyByDesign
        ? 'Solo only — single-player by design'
        : 'Solo only — multiplayer coming soon';

    return SisuTileCard(
      elevation: 4,
      color: SisuColors.getTileColor(isDark),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            Opacity(
              opacity: soloOnly ? 0.45 : 1.0,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: Container(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.04)
                          : SisuColors.completedBackground
                              .withValues(alpha: 0.08),
                      padding: const EdgeInsets.all(12),
                      child: Image.asset(
                        iconPath,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) => Icon(
                          Icons.casino,
                          size: 48,
                          color: SisuColors.completedBackground,
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(8, 8, 8, 10),
                    child: Text(
                      title,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: titleColor,
                            height: 1.15,
                          ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            if (isMultiplayerReady)
              Positioned(
                top: 6,
                right: 6,
                child: Tooltip(
                  message: 'Multiplayer ready: $title',
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: SisuColors.completedBackground
                          .withValues(alpha: 0.9),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.wifi,
                      size: 14,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            if (soloOnly)
              Positioned(
                top: 6,
                right: 6,
                child: Tooltip(
                  message: soloTooltip,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(
                      color: SisuColors.getListSurface(isDark)
                          .withValues(alpha: 0.92),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Solo only',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: SisuColors.getTextSecondaryColor(isDark),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
