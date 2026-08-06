import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../../models/models.dart';
import '../../providers/shopping_provider.dart';
import '../../core/di.dart';
import '../../core/colors.dart';
import '../../services/error_log_service.dart';

/// Universal Title Tile that replaces the status bar across all screens.
///
/// Title-bar standard (owner, 2026-07-12 — see theme.md §5.1):
/// - Line 1: the screen title. Line 2 is ALWAYS the status line
///   (boat • Pro/Free • Online/Offline • email user • Syncing (N)).
/// - A back arrow sits on the far left whenever the screen can pop
///   (the home screen can't, so it never shows one).
/// - Trailing icons, right to left: drawer (menu), import/export, share.
class TitleTile extends ConsumerStatefulWidget {
  /// The main title to display (context-aware, e.g., "Sisu Mate", "Checklists", "Daily Engine Checks")
  final String title;

  /// Optional callback for menu button press
  final VoidCallback? onMenuPressed;

  /// Optional extra icon buttons rendered before the menu icon (e.g. share/print).
  /// Receives the tile's computed icon color so actions match the header style.
  final List<Widget> Function(Color iconColor)? actionsBuilder;

  const TitleTile({
    super.key,
    required this.title,
    this.onMenuPressed,
    this.actionsBuilder,
  });

  @override
  ConsumerState<TitleTile> createState() => _TitleTileState();
}

class _TitleTileState extends ConsumerState<TitleTile> {
  List<ConnectivityResult> _connectivity = [ConnectivityResult.none];

  @override
  void initState() {
    super.initState();
    _initConnectivity();
    Connectivity().onConnectivityChanged.listen(_updateConnectivity);
  }

  Future<void> _initConnectivity() async {
    try {
      final result = await Connectivity().checkConnectivity();
      _updateConnectivity(result);
    } catch (e) {
      unawaited(ErrorLogService()
          .logWarning('connectivity check failed: $e', context: 'title_tile: _initConnectivity'));
    }
  }

  void _updateConnectivity(List<ConnectivityResult> result) {
    if (mounted) {
      setState(() => _connectivity = result);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isProAsync = ref.watch(isProProvider);
    final activeBoatAsync = ref.watch(activeBoatProvider);
    final userAsync = ref.watch(authStateProvider);

    return isProAsync.when(
      data: (isPro) => activeBoatAsync.when(
        data: (boat) => userAsync.when(
          data: (user) => _buildTitleTile(isPro, boat, user),
          loading: () => _buildTitleTile(isPro, boat, null),
          error: (_, _) => _buildTitleTile(isPro, boat, null),
        ),
        loading: () => _buildTitleTile(isPro, null, null),
        error: (_, _) => _buildTitleTile(isPro, null, null),
      ),
      loading: () => _buildTitleTile(false, null, null),
      error: (_, _) => _buildTitleTile(false, null, null),
    );
  }

  Widget _buildTitleTile(bool isPro, Boat? activeBoat, dynamic user) {
    final isOnline = _connectivity.any(
      (result) => result != ConnectivityResult.none,
    );
    final backgroundColor = SisuColors.getStatusBarColor(isPro, isOnline);
    final textColor = Theme.of(context).colorScheme.onPrimary;

    // Status line (mandatory): Boat • Pro/Free • Online/Offline • user • Syncing (N)
    final boatName = activeBoat?.name ?? 'No Boat';
    final proStatus = isPro ? 'Pro' : 'Free';
    final onlineStatus = isPro ? (isOnline ? 'Online' : 'Offline') : '';
    final username = isPro && user != null
        ? user.email?.split('@')[0] ?? ''
        : '';
    final outbox = ref.watch(syncOutboxCountProvider).value ?? 0;

    final secondLineParts = [boatName, proStatus];
    if (onlineStatus.isNotEmpty) secondLineParts.add(onlineStatus);
    if (username.isNotEmpty) secondLineParts.add(username);
    if (outbox > 0) secondLineParts.add('Syncing ($outbox)');

    final secondLine = secondLineParts.join(' • ');
    final canPop = Navigator.of(context).canPop();

    // #269 / #279 — compact 40×40 icons avoid the old 48×48 overflow on
    // ~320-wide phones. Trailing must NOT be Flexible (that shared flex with
    // the title Expanded and crushed the title / moved the menu off far-right).
    // Layout: [back?] [Expanded title…] [actions… menu] — menu always last
    // so it stays flush right; actions pack immediately to its left.
    Widget compactIconButton({
      required IconData icon,
      required VoidCallback onPressed,
      required String tooltip,
      Key? key,
    }) {
      return IconButton(
        key: key,
        icon: Icon(icon, color: textColor),
        onPressed: onPressed,
        tooltip: tooltip,
        visualDensity: VisualDensity.compact,
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
        style: IconButton.styleFrom(
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
      );
    }

    final actionExtras = widget.actionsBuilder?.call(textColor) ?? const <Widget>[];
    final showMenu = widget.onMenuPressed != null;

    // Force compact density on caller-supplied IconButtons too.
    final compactActionTheme = Theme.of(context).copyWith(
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: textColor,
          visualDensity: VisualDensity.compact,
          padding: EdgeInsets.zero,
          minimumSize: const Size(40, 40),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
      ),
    );

    return Container(
      width: double.infinity,
      height: 62,
      color: backgroundColor,
      padding: EdgeInsets.only(
        left: canPop ? 0 : 16,
        right: showMenu || actionExtras.isNotEmpty ? 4 : 16,
        top: 6,
        bottom: 6,
      ),
      child: Row(
        children: [
          if (canPop)
            compactIconButton(
              key: const ValueKey('title_tile_back'),
              icon: Icons.arrow_back,
              onPressed: () => Navigator.of(context).maybePop(),
              tooltip: 'Back',
            ),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.title,
                  style: TextStyle(
                    color: textColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
                const SizedBox(height: 1),
                // Full opacity — alpha < 1 failed WCAG 4.5:1 on dark theme (TEST10).
                Text(
                  secondLine,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 11,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ],
            ),
          ),
          if (actionExtras.isNotEmpty || showMenu)
            Theme(
              data: compactActionTheme,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ...actionExtras,
                  if (showMenu)
                    compactIconButton(
                      key: const ValueKey('title_tile_menu'),
                      icon: Icons.menu,
                      onPressed: widget.onMenuPressed!,
                      tooltip: 'Menu',
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
