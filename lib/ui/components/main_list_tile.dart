import 'package:flutter/material.dart';
import '../../core/colors.dart';

/// Shared **main-list** card (theme.md §5 — Chef is the reference).
///
/// Two-column grids of these tiles: icon/image, title, tags, count, time/cost,
/// attention line, optional badges. Content is clipped so fixed-aspect grids
/// never throw RenderFlex overflow.
class MainListTile extends StatelessWidget {
  final VoidCallback onTap;
  final Widget header;
  final String title;
  final List<String> tags;
  final Color? tagColor;
  final String? countLine;
  final String? metaLine;
  final String? attentionLine;
  final List<String> badges;
  final Widget? headerOverlay;

  const MainListTile({
    super.key,
    required this.onTap,
    required this.header,
    required this.title,
    this.tags = const [],
    this.tagColor,
    this.countLine,
    this.metaLine,
    this.attentionLine,
    this.badges = const [],
    this.headerOverlay,
  });

  /// Compact icon header used by most non-photo modules.
  static Widget iconHeader({
    required IconData icon,
    required Color iconColor,
    Color? background,
    double height = 64,
  }) {
    return Builder(
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Container(
          height: height,
          width: double.infinity,
          decoration: BoxDecoration(
            color: background ??
                (isDark
                    ? Colors.white.withValues(alpha: 0.06)
                    : iconColor.withValues(alpha: 0.12)),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(12),
              topRight: Radius.circular(12),
            ),
          ),
          child: Center(child: Icon(icon, size: 32, color: iconColor)),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final titleColor = SisuColors.getTextPrimaryColor(isDark);
    final secondary = SisuColors.getTextSecondaryColor(isDark);
    final chipColor = tagColor ?? SisuColors.completedBackground;

    return Card(
      elevation: 4,
      color: SisuColors.getTileColor(isDark),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Stack(
              children: [
                header,
                if (headerOverlay != null)
                  Positioned(top: 0, right: 0, child: headerOverlay!),
              ],
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
                // ScrollView gives unbounded height so the Column never
                // reports RenderFlex overflow; clip hides excess on short tiles.
                child: SingleChildScrollView(
                  physics: const NeverScrollableScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        style:
                            Theme.of(context).textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: titleColor,
                                  height: 1.15,
                                ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (tags.isNotEmpty) ...[
                        const SizedBox(height: 3),
                        _chipRow(
                          tags.take(2).map(
                                (t) => _MainListChip(
                                    label: t, color: chipColor),
                              ),
                        ),
                      ],
                      if (countLine != null) ...[
                        const SizedBox(height: 3),
                        Text(
                          countLine!,
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: SisuColors.incompleteBackground,
                                    fontWeight: FontWeight.w600,
                                    height: 1.1,
                                  ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      if (metaLine != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          metaLine!,
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: secondary,
                                    height: 1.1,
                                  ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      if (attentionLine != null) ...[
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            Icon(Icons.warning_amber,
                                size: 12,
                                color: Theme.of(context).colorScheme.error),
                            const SizedBox(width: 2),
                            Expanded(
                              child: Text(
                                attentionLine!,
                                style: TextStyle(
                                  fontSize: 10,
                                  height: 1.1,
                                  color: Theme.of(context).colorScheme.error,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                      if (badges.isNotEmpty) ...[
                        const SizedBox(height: 3),
                        _chipRow(
                          badges.take(2).map(
                                (b) =>
                                    _MainListChip(label: b, color: secondary),
                              ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _chipRow(Iterable<Widget> chips) {
    return SizedBox(
      height: 18,
      child: ListView(
        scrollDirection: Axis.horizontal,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          for (final c in chips) ...[
            c,
            const SizedBox(width: 4),
          ],
        ],
      ),
    );
  }
}

class _MainListChip extends StatelessWidget {
  final String label;
  final Color color;
  const _MainListChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.45), width: 0.5),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          color: color,
          fontWeight: FontWeight.w600,
          height: 1.1,
        ),
      ),
    );
  }
}

/// Search field used under [TitleTile] on main-list screens (theme.md §5).
class MainListSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final ValueChanged<String> onChanged;

  const MainListSearchBar({
    super.key,
    required this.controller,
    required this.hintText,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          hintText: hintText,
          prefixIcon: const Icon(Icons.search),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          filled: true,
          fillColor: Theme.of(context).cardColor,
          isDense: true,
        ),
        onChanged: onChanged,
      ),
    );
  }
}
