import 'package:flutter/material.dart';
import '../../core/colors.dart';

/// Raised, state-coloured list row (theme.md §6). Colour tells the state —
/// no tick / cart / status icons on the tile itself.
///
/// Pair with [SwipeableListItem] for uniform swipe actions (§6.6).
class ThemedStateTile extends StatelessWidget {
  final ItemListState state;
  final Widget? leading;
  final String title;
  final String? subtitle;
  final String? tertiary;
  final Widget? trailing;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry margin;

  const ThemedStateTile({
    super.key,
    required this.state,
    required this.title,
    this.leading,
    this.subtitle,
    this.tertiary,
    this.trailing,
    this.onTap,
    this.margin = const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final c = SisuColors.itemStateColors(isDark, state);
    final multiLine = (subtitle != null && tertiary != null);

    return Card(
      margin: margin,
      color: c.bg,
      elevation: 3,
      child: ListTile(
        isThreeLine: multiLine,
        leading: leading,
        title: Text(
          title,
          style: TextStyle(color: c.title, fontWeight: FontWeight.w600),
        ),
        subtitle: (subtitle == null && tertiary == null)
            ? null
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (subtitle != null)
                    Text(subtitle!, style: TextStyle(color: c.desc)),
                  if (tertiary != null)
                    Text(
                      tertiary!,
                      style: TextStyle(
                        color: c.desc.withValues(alpha: 0.85),
                        fontSize: 12,
                      ),
                    ),
                ],
              ),
        trailing: trailing,
        onTap: onTap,
      ),
    );
  }
}
