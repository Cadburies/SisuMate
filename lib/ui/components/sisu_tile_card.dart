import 'package:flutter/material.dart';
import '../../core/colors.dart';

/// Raised card filled with [SisuColors.tonalBarGradient] (theme.md §2.1).
/// Drop-in for `Card(color: token, …)` on title-adjacent tiles.
class SisuTileCard extends StatelessWidget {
  final Color color;
  final Widget child;
  final EdgeInsetsGeometry? margin;
  final double elevation;
  final ShapeBorder? shape;
  final Clip clipBehavior;

  const SisuTileCard({
    super.key,
    required this.color,
    required this.child,
    this.margin,
    this.elevation = 3,
    this.shape,
    this.clipBehavior = Clip.antiAlias,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: margin,
      elevation: elevation,
      color: Colors.transparent,
      shadowColor: Colors.black,
      surfaceTintColor: Colors.transparent,
      shape: shape ??
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: clipBehavior,
      child: Ink(
        decoration: BoxDecoration(gradient: SisuColors.tonalBarGradient(color)),
        child: child,
      ),
    );
  }
}
