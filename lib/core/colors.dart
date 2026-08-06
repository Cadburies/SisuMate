import 'package:flutter/material.dart';

/// Sisu Mate canonical color system.
/// PRD palette: teal + blue-grey + Nunito — marine/offshore aesthetic.
/// This is the single source of truth. Do NOT define SisuColors elsewhere.
class SisuColors {
  // ── Status Bar ─────────────────────────────────────────────────────────────
  // Four combinations: Pro/Free × Online/Offline. Kept deliberately dark so the
  // title bar reads as part of the dark theme (theme.md), hue still distinguishes.
  static const Color proOnline = Color(0xFF00504F);   // deep teal   — Pro + connected
  static const Color proOffline = Color(0xFF285C3C);  // deep green  — Pro + offline
  static const Color freeOnline = Color(0xFF3A4A52);  // dark blue-grey — Free + connected
  static const Color freeOffline = Color(0xFF2C383E); // darker blue-grey — Free + offline

  // ── Item Status ────────────────────────────────────────────────────────────
  static const Color completedBackground = Color(0xFF006666);  // dark teal
  static const Color completedText = Color(0xFF80deea);        // light teal/cyan
  static const Color incompleteBackground = Color(0xFF546e7a); // blue-grey
  static const Color incompleteText = Color(0xFFb0bec5);       // light blue-grey
  static const Color hiddenBackground = Color(0xFF37474f);     // dark blue-grey
  static const Color hiddenText = Color(0xFF78909c);           // medium blue-grey
  // Visible slate for the swipe "Hide" action (the dark hiddenBackground looked
  // disabled as a button).
  static const Color hideAction = Color(0xFF546E7A);           // slate blue-grey
  static const Color notAvailableBackground = Color(0xFFcc0000); // dark red (error)
  static const Color notAvailableText = Color(0xFFff6b6b);      // coral red

  // ── Light Theme Surface Colors ─────────────────────────────────────────────
  static const Color lightBackground = Color(0xFFf5f5f5); // light grey scaffold
  static const Color lightSurface = Color(0xFFffffff);    // white cards
  static const Color lightTextPrimary = Color(0xFF263238);   // dark blue-grey
  static const Color lightTextSecondary = Color(0xFF546e7a); // medium blue-grey

  // ── Dark Theme Surface Colors ──────────────────────────────────────────────
  static const Color darkBackground = Color(0xFF121212); // near-black scaffold
  static const Color darkSurface = Color(0xFF1e1e1e);    // dark surface cards
  static const Color darkTextPrimary = Color(0xFFffffff);    // white
  static const Color darkTextSecondary = Color(0xFFb0bec5); // light blue-grey

  // ── Three-Layer Background System (theme.md §3) ─────────────────────────────
  // Scaffold (darkest) → list/surface → raised tile. Light theme mirrors it.
  // Use the getXxx helpers below; add new tokens here, never inline hex.
  static const Color darkAppBackground = Color(0xFF0D0D0D); // scaffold (darkest)
  static const Color darkListSurface = darkBackground;      // #121212 surface
  static const Color darkTile = darkSurface;                // #1e1e1e raised tile

  static const Color lightAppBackground = Color(0xFFE8E8E8); // scaffold (lightest)
  static const Color lightListSurface = lightBackground;     // #f5f5f5 surface
  static const Color lightTile = lightSurface;               // white raised tile

  static Color getAppBackground(bool isDark) =>
      isDark ? darkAppBackground : lightAppBackground;
  static Color getListSurface(bool isDark) =>
      isDark ? darkListSurface : lightListSurface;
  static Color getTileColor(bool isDark) => isDark ? darkTile : lightTile;

  // Main-screen module tiles (theme.md §4): a blue-grey in the title-bar family
  // but darker, so the grid reads as one cohesive surface. Icons keep their
  // per-module accent colour for identity.
  static const Color darkHomeTile = Color(0xFF2E3D45);  // dark blue-grey
  static const Color lightHomeTile = Color(0xFFCFD8DC); // blue-grey 100
  static Color getHomeTile(bool isDark) =>
      isDark ? darkHomeTile : lightHomeTile;

  // ── Tile Elevation (theme.md §2) — the "elegant separator". ─────────────────
  static List<BoxShadow> tileElevation(bool isDark) => [
        BoxShadow(
          color: isDark
              ? const Color(0xCC000000) // ~80% black — depth on dark grey
              : const Color(0x1F000000), // ~12% black
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ];

  // ── Item State Palette (theme.md §6.5) — the tile colour tells the state. ───
  // Each state: background + description text (lighter) + title text (lightest).
  // Dark defaults; light variants below. Prefer [itemStateColors].
  // Default / not completed
  static const Color stateDefaultBg = Color(0xFF2E373D);
  static const Color stateDefaultDesc = Color(0xFFAEB8BF);
  static const Color stateDefaultTitle = Color(0xFFECEFF1);
  // In stock / completed — green
  static const Color stateStockedBg = Color(0xFF14532D);
  static const Color stateStockedDesc = Color(0xFF86EFAC);
  static const Color stateStockedTitle = Color(0xFFDCFCE7);
  // In shopping basket — blue
  static const Color stateShoppingBg = Color(0xFF13386E);
  static const Color stateShoppingDesc = Color(0xFF93C5FD);
  static const Color stateShoppingTitle = Color(0xFFDBEAFE);
  // Not in stock / deleted — red
  static const Color stateUnavailableBg = Color(0xFF6E1D1D);
  static const Color stateUnavailableDesc = Color(0xFFFCA5A5);
  static const Color stateUnavailableTitle = Color(0xFFFEE2E2);
  // Hidden — clearly darker/"faded" than the default tile.
  static const Color stateHiddenBg = Color(0xFF16191B);
  static const Color stateHiddenDesc = Color(0xFF61696E);
  static const Color stateHiddenTitle = Color(0xFF8A9296);

  // Light-theme state palette (UX4)
  static const Color lightStateDefaultBg = Color(0xFFECEFF1);
  static const Color lightStateDefaultDesc = Color(0xFF546E7A);
  static const Color lightStateDefaultTitle = Color(0xFF263238);
  static const Color lightStateStockedBg = Color(0xFFC8E6C9);
  static const Color lightStateStockedDesc = Color(0xFF2E7D32);
  static const Color lightStateStockedTitle = Color(0xFF1B5E20);
  static const Color lightStateShoppingBg = Color(0xFFBBDEFB);
  static const Color lightStateShoppingDesc = Color(0xFF1565C0);
  static const Color lightStateShoppingTitle = Color(0xFF0D47A1);
  static const Color lightStateUnavailableBg = Color(0xFFFFCDD2);
  static const Color lightStateUnavailableDesc = Color(0xFFC62828);
  static const Color lightStateUnavailableTitle = Color(0xFFB71C1C);
  static const Color lightStateHiddenBg = Color(0xFFCFD8DC);
  static const Color lightStateHiddenDesc = Color(0xFF78909C);
  static const Color lightStateHiddenTitle = Color(0xFF546E7A);

  // ── Dialog Buttons (theme.md / #126) ─────────────────────────────────────
  // AlertDialog action buttons (Save/Confirm/Delete) need a solid background
  // with a high-contrast label — the pale *Text tile tokens above (tuned for
  // large tile areas) fall well under WCAG AA at button-label scale. Reuses
  // existing background tokens (completedBackground = confirm, notAvailable-
  // Background = destructive) with one dedicated on-color, since both are
  // dark enough to need the same light label in both themes.
  static const Color dialogButtonOnColor = Color(0xFFFFFFFF);

  // ── General UI ────────────────────────────────────────────────────────────
  // Use these only when you cannot use the Theme; prefer Theme.of(context) in widgets.
  static const Color background = lightBackground;
  static const Color cardBackground = lightSurface;
  static const Color primaryText = lightTextPrimary;

  // ── Theme-Aware Helpers ────────────────────────────────────────────────────
  // Pass isDark from ThemeData: Theme.of(context).brightness == Brightness.dark

  static Color getBackgroundColor(bool isDark) =>
      isDark ? darkBackground : lightBackground;

  static Color getSurfaceColor(bool isDark) =>
      isDark ? darkSurface : lightSurface;

  static Color getTextPrimaryColor(bool isDark) =>
      isDark ? darkTextPrimary : lightTextPrimary;

  static Color getTextSecondaryColor(bool isDark) =>
      isDark ? darkTextSecondary : lightTextSecondary;

  // ── Status Helpers ─────────────────────────────────────────────────────────

  static Color getStatusBarColor(bool isPro, bool isOnline) {
    if (isPro) return isOnline ? proOnline : proOffline;
    return isOnline ? freeOnline : freeOffline;
  }

  static Color? getItemBackgroundColor(bool isCompleted, bool isHidden) {
    if (isHidden) return hiddenBackground;
    if (isCompleted) return completedBackground;
    return incompleteBackground;
  }

  static Color? getItemTextColor(bool isCompleted, bool isHidden) {
    if (isHidden) return hiddenText;
    if (isCompleted) return completedText;
    return incompleteText;
  }

  static Color getNotAvailableColor({bool isBackground = false}) =>
      isBackground ? notAvailableBackground : notAvailableText;

  // ── Sea-state polar chart (#276) — reuses status tokens ───────────────────
  // calm = teal (target), moderate = blue-grey, rough = coral/red.
  static Color seaStateLineColor(String seaStateWire) {
    switch (seaStateWire) {
      case 'calm':
        return completedText;
      case 'moderate':
        return incompleteText;
      case 'rough':
        return notAvailableText;
      default:
        return darkTextSecondary;
    }
  }

  static Color seaStateChipBg(String seaStateWire) {
    switch (seaStateWire) {
      case 'calm':
        return completedBackground;
      case 'moderate':
        return incompleteBackground;
      case 'rough':
        return notAvailableBackground;
      default:
        return hiddenBackground;
    }
  }

  /// Theme-aware item-list state colours (theme.md §6.5). Use for UX4 tiles.
  static ItemListStateColors itemStateColors(
    bool isDark,
    ItemListState state,
  ) {
    switch (state) {
      case ItemListState.stocked:
        return isDark
            ? const ItemListStateColors(
                bg: stateStockedBg,
                title: stateStockedTitle,
                desc: stateStockedDesc,
              )
            : const ItemListStateColors(
                bg: lightStateStockedBg,
                title: lightStateStockedTitle,
                desc: lightStateStockedDesc,
              );
      case ItemListState.shopping:
        return isDark
            ? const ItemListStateColors(
                bg: stateShoppingBg,
                title: stateShoppingTitle,
                desc: stateShoppingDesc,
              )
            : const ItemListStateColors(
                bg: lightStateShoppingBg,
                title: lightStateShoppingTitle,
                desc: lightStateShoppingDesc,
              );
      case ItemListState.unavailable:
        return isDark
            ? const ItemListStateColors(
                bg: stateUnavailableBg,
                title: stateUnavailableTitle,
                desc: stateUnavailableDesc,
              )
            : const ItemListStateColors(
                bg: lightStateUnavailableBg,
                title: lightStateUnavailableTitle,
                desc: lightStateUnavailableDesc,
              );
      case ItemListState.hidden:
        return isDark
            ? const ItemListStateColors(
                bg: stateHiddenBg,
                title: stateHiddenTitle,
                desc: stateHiddenDesc,
              )
            : const ItemListStateColors(
                bg: lightStateHiddenBg,
                title: lightStateHiddenTitle,
                desc: lightStateHiddenDesc,
              );
      case ItemListState.defaults:
        return isDark
            ? const ItemListStateColors(
                bg: stateDefaultBg,
                title: stateDefaultTitle,
                desc: stateDefaultDesc,
              )
            : const ItemListStateColors(
                bg: lightStateDefaultBg,
                title: lightStateDefaultTitle,
                desc: lightStateDefaultDesc,
              );
    }
  }
}

/// Visual state for item-list tiles (theme.md §6.5).
enum ItemListState {
  /// Not completed / not in stock / normal row.
  defaults,
  /// Completed / in bar / in pantry / bought.
  stocked,
  /// In shopping basket (shopping list origin or flag).
  shopping,
  /// Deleted / not available.
  unavailable,
  /// Soft-hidden.
  hidden,
}

/// bg + title + description colours for one [ItemListState].
class ItemListStateColors {
  final Color bg;
  final Color title;
  final Color desc;
  const ItemListStateColors({
    required this.bg,
    required this.title,
    required this.desc,
  });
}

/// Convenience extension — use `.subtitle` to get a 70 % opacity variant.
extension SisuColorExtensions on Color? {
  Color? get subtitle => this?.withValues(alpha: 0.7);
}
