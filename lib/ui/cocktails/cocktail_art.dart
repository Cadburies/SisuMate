import 'package:flutter/material.dart';
import '../../core/colors.dart';
import '../components/smart_image.dart';

/// Bundled cocktail JPEGs are 720×480 (3:2). Putting them in a much wider,
/// short box with [BoxFit.cover] (iPad full-bleed × 90/200) crops through the
/// glass and looks like a corrupted strip.
class CocktailArt extends StatelessWidget {
  static const double aspectRatio = 3 / 2;
  static const double detailMaxWidth = 480;

  final String? assetName;
  final String? userPhotoPath;
  final bool detail;

  const CocktailArt({
    super.key,
    this.assetName,
    this.userPhotoPath,
    this.detail = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fallbackColor = SisuColors.getTileColor(isDark);
    final iconColor =
        SisuColors.getTextPrimaryColor(isDark).withValues(alpha: 0.55);

    Widget image({required double width, required double height}) {
      return SmartImage(
        assetName: assetName,
        userPhotoPath: userPhotoPath,
        width: width,
        height: height,
        fit: BoxFit.cover,
        customFallback: ColoredBox(
          color: fallbackColor,
          child: Icon(
            Icons.local_bar,
            size: detail ? 56 : 36,
            color: iconColor,
          ),
        ),
      );
    }

    if (!detail) {
      return AspectRatio(
        aspectRatio: aspectRatio,
        child: LayoutBuilder(
          builder: (context, c) =>
              image(width: c.maxWidth, height: c.maxHeight),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, c) {
        final maxW = c.maxWidth.isFinite ? c.maxWidth : detailMaxWidth;
        final width = maxW < detailMaxWidth ? maxW : detailMaxWidth;
        final height = width / aspectRatio;
        return Center(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              width: width,
              height: height,
              child: image(width: width, height: height),
            ),
          ),
        );
      },
    );
  }
}
