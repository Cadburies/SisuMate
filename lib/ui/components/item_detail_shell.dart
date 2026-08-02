import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/colors.dart';
import 'title_tile.dart';

/// One sticky-bar action for [ItemDetailShell] (theme.md §7).
class DetailAction {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  /// Background hinting the state this item moves *into* if tapped (e.g.
  /// the completed-state color for a "Complete" action). Null falls back to
  /// a neutral tile background.
  final Color? color;
  /// Text/icon color paired with [color] (theme.md §6.5 state title tokens
  /// pair naturally with state background tokens). Null auto-derives a
  /// readable color from [color]'s luminance.
  final Color? onColor;

  const DetailAction({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.color,
    this.onColor,
  });
}

/// Readable icon/label color for an arbitrary background — used when a
/// [DetailAction] doesn't pair its [DetailAction.color] with an explicit
/// [DetailAction.onColor] (theme.md §6.5 state tokens already come in pairs;
/// this is the fallback for the handful of actions that don't).
Color _autoOnColor(Color background) =>
    ThemeData.estimateBrightnessForColor(background) == Brightness.dark
        ? Colors.white
        : Colors.black87;

/// Shared swipeable item-detail shell (theme.md §7).
///
/// - Swipe between items ([PageView]; locked while editing)
/// - Image area (optional) with optional change-photo control
/// - Content (display or edit) via [contentBuilder]
/// - Sticky action bar above a history list
/// - [TitleTile] with optional end-drawer (menu button)
class ItemDetailShell extends ConsumerStatefulWidget {
  final int itemCount;
  final int initialIndex;
  final String Function(int index) titleForIndex;
  final String? Function(int index)? subtitleForIndex;
  final Widget Function(BuildContext context, int index, bool isEditing)
      contentBuilder;
  final Widget? Function(BuildContext context, int index)? imageBuilder;
  final VoidCallback? Function(int index)? onChangePhoto;
  final List<String> Function(int index)? historyForIndex;
  final List<DetailAction> Function(
    BuildContext context,
    int index,
    bool isEditing,
    VoidCallback startEdit,
    VoidCallback cancelEdit,
    Future<void> Function() saveEdit,
  ) actionsForIndex;
  final Future<void> Function(int index)? onSaveEdit;
  final Widget? endDrawer;
  final Color? Function(int index)? stateColorForIndex;

  const ItemDetailShell({
    super.key,
    required this.itemCount,
    required this.initialIndex,
    required this.titleForIndex,
    this.subtitleForIndex,
    required this.contentBuilder,
    this.imageBuilder,
    this.onChangePhoto,
    this.historyForIndex,
    required this.actionsForIndex,
    this.onSaveEdit,
    this.endDrawer,
    this.stateColorForIndex,
  });

  @override
  ConsumerState<ItemDetailShell> createState() => _ItemDetailShellState();
}

class _ItemDetailShellState extends ConsumerState<ItemDetailShell> {
  late PageController _pageController;
  late int _currentIndex;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    final safe = widget.itemCount == 0
        ? 0
        : widget.initialIndex.clamp(0, widget.itemCount - 1);
    _currentIndex = safe;
    _pageController = PageController(initialPage: safe);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _startEdit() => setState(() => _isEditing = true);

  void _cancelEdit() => setState(() => _isEditing = false);

  Future<void> _saveEdit() async {
    final save = widget.onSaveEdit;
    if (save != null) await save(_currentIndex);
    if (!mounted) return;
    setState(() => _isEditing = false);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = SisuColors.getAppBackground(isDark);
    final count = widget.itemCount;
    if (count == 0) {
      return Scaffold(
        backgroundColor: bg,
        body: SafeArea(
          child: Column(
            children: [
              TitleTile(
                title: 'No items',
                onMenuPressed: widget.endDrawer != null
                    ? () => Scaffold.of(context).openEndDrawer()
                    : null,
              ),
              const Expanded(child: Center(child: Text('Nothing to show'))),
            ],
          ),
        ),
        endDrawer: widget.endDrawer,
      );
    }

    final title = widget.titleForIndex(_currentIndex);
    final subtitle = widget.subtitleForIndex?.call(_currentIndex) ??
        '${_currentIndex + 1} of $count';
    final history = widget.historyForIndex?.call(_currentIndex) ?? const <String>[];
    final actions = widget.actionsForIndex(
      context,
      _currentIndex,
      _isEditing,
      _startEdit,
      _cancelEdit,
      _saveEdit,
    );
    final stateColor = widget.stateColorForIndex?.call(_currentIndex);

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Column(
          children: [
            Builder(
              builder: (tileContext) => TitleTile(
                title: title,
                onMenuPressed: widget.endDrawer != null
                    ? () => Scaffold.of(tileContext).openEndDrawer()
                    : null,
              ),
            ),
            // Header row below the title bar (theme.md §6.3): group/position
            // context (e.g. "On-Watch Checks · 3 of 16") — UX7, resurfaced
            // here after the title bar's second line became the mandatory
            // status line (§5.1) and could no longer carry per-item text.
            Container(
              width: double.infinity,
              color: SisuColors.getListSurface(isDark),
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
              child: Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: SisuColors.getTextSecondaryColor(isDark),
                ),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                physics: _isEditing
                    ? const NeverScrollableScrollPhysics()
                    : const PageScrollPhysics(),
                itemCount: count,
                onPageChanged: (i) {
                  setState(() {
                    _currentIndex = i;
                    _isEditing = false;
                  });
                },
                itemBuilder: (context, index) {
                  final image = widget.imageBuilder?.call(context, index);
                  final onPhoto = widget.onChangePhoto?.call(index);
                  final pageState = widget.stateColorForIndex?.call(index);
                  const imageHeight = 200.0;
                  // A fixed-height image box + Expanded content can overflow
                  // by a few px on some devices/frames — the image height is
                  // non-negotiable, but Expanded's minimum is 0, so it can't
                  // absorb the shortfall. LayoutBuilder + a scrollable with a
                  // minHeight constraint keeps the "fill the page" look in
                  // the normal case while degrading to a (imperceptible, a
                  // few px) scroll instead of a hard overflow when it
                  // doesn't quite fit (#161).
                  return LayoutBuilder(
                    builder: (context, constraints) {
                      return SingleChildScrollView(
                        child: ConstrainedBox(
                          constraints:
                              BoxConstraints(minHeight: constraints.maxHeight),
                          child: Column(
                            children: [
                              if (image != null)
                                SizedBox(
                                  height: imageHeight,
                                  width: double.infinity,
                                  child: Stack(
                                    fit: StackFit.expand,
                                    children: [
                                      image,
                                      if (onPhoto != null)
                                        Positioned(
                                          right: 12,
                                          bottom: 12,
                                          child: FloatingActionButton.small(
                                            heroTag: 'detail_photo_$index',
                                            onPressed: onPhoto,
                                            tooltip: 'Change photo',
                                            child:
                                                const Icon(Icons.add_a_photo),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ConstrainedBox(
                                constraints: BoxConstraints(
                                  // #206: on a short screen (or a transient
                                  // frame where the sliver hasn't settled to
                                  // its final height yet), maxHeight can be
                                  // less than the fixed image height, making
                                  // this go negative — BoxConstraints forbids
                                  // that. Clamp to 0; the content box just
                                  // won't force extra height in that case,
                                  // same graceful-degradation intent as the
                                  // #161 comment above.
                                  minHeight: (constraints.maxHeight -
                                          (image != null ? imageHeight : 0))
                                      .clamp(0.0, double.infinity),
                                ),
                                child: Container(
                                  width: double.infinity,
                                  color: pageState ??
                                      SisuColors.getListSurface(isDark),
                                  padding:
                                      const EdgeInsets.fromLTRB(16, 12, 16, 8),
                                  child: widget.contentBuilder(
                                    context,
                                    index,
                                    _isEditing && index == _currentIndex,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            // Sticky actions (theme.md §7) — always above history.
            Material(
              elevation: 4,
              color: stateColor ?? SisuColors.getSurfaceColor(isDark),
              child: SafeArea(
                top: false,
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      for (final a in actions)
                        _ActionButton(
                          icon: a.icon,
                          label: a.label,
                          onPressed: a.onPressed,
                          color: a.color ?? SisuColors.getTileColor(isDark),
                          onColor: a.onColor ??
                              _autoOnColor(
                                  a.color ?? SisuColors.getTileColor(isDark)),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            // History pane — scrolls under the action bar.
            Container(
              height: 120,
              width: double.infinity,
              color: SisuColors.getListSurface(isDark),
              child: history.isEmpty
                  ? Center(
                      child: Text(
                        'No history yet',
                        style: TextStyle(
                          color: SisuColors.getTextSecondaryColor(isDark),
                          fontSize: 13,
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      itemCount: history.length,
                      itemBuilder: (_, i) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 3),
                        child: Row(
                          children: [
                            Icon(
                              Icons.history,
                              size: 16,
                              color: SisuColors.getTextSecondaryColor(isDark),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                history[i],
                                style: TextStyle(
                                  fontSize: 13,
                                  color:
                                      SisuColors.getTextPrimaryColor(isDark),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
      endDrawer: widget.endDrawer,
    );
  }
}

/// A framed, elevated chip-button — background hints the state this action
/// moves the item into, so it reads as a button on its own rather than
/// blending into a sticky bar that may share the same background color as
/// the *current* state (the #185 bug: a green "Uncomplete" on a green
/// completed-state bar was nearly invisible).
class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final Color color;
  final Color onColor;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    required this.color,
    required this.onColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3),
      child: Material(
        color: color,
        elevation: 2,
        shadowColor: Colors.black.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: onColor.withValues(alpha: 0.3)),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: onColor, size: 20),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: TextStyle(
                    color: onColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
