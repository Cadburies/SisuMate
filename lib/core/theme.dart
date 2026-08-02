import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'colors.dart';
import 'di.dart';
import '../services/error_log_service.dart';

// ── Theme Mode State ──────────────────────────────────────────────────────────

class ThemeModeNotifier extends Notifier<ThemeMode> {
  // Dark is the default (theme.md §1).
  @override
  ThemeMode build() => ThemeMode.dark;

  void toggleTheme() {
    final next = state == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    state = next;
    _persist(next);
  }

  void setLightTheme() {
    state = ThemeMode.light;
    _persist(ThemeMode.light);
  }

  void setDarkTheme() {
    state = ThemeMode.dark;
    _persist(ThemeMode.dark);
  }

  /// Restores the persisted theme on startup without triggering another write.
  void restoreTheme(bool isDark) {
    state = isDark ? ThemeMode.dark : ThemeMode.light;
  }

  Future<void> _persist(ThemeMode mode) async {
    try {
      final settings = await ref.read(userSettingsProvider.future);
      if (settings == null) return;
      settings.isDarkMode = mode == ThemeMode.dark;
      await ref.read(userSettingsRepositoryProvider).updateSettings(settings);
    } catch (e) {
      // Best-effort — next successful call will catch up
      unawaited(ErrorLogService()
          .logWarning('theme mode failed to persist: $e', context: 'theme: _persist'));
    }
  }
}

final themeModeProvider = NotifierProvider<ThemeModeNotifier, ThemeMode>(
  ThemeModeNotifier.new,
);

// ── Theme Builder ─────────────────────────────────────────────────────────────

ThemeData createSisuMateTheme({required Brightness brightness}) {
  final isDark = brightness == Brightness.dark;

  final colorScheme = ColorScheme(
    brightness: brightness,
    // Surfaces — the middle "list/surface" layer (theme.md §3)
    surface: SisuColors.getListSurface(isDark),
    onSurface: SisuColors.getTextPrimaryColor(isDark),
    // Primary maps to "incomplete" — the default resting state of list items
    primary: SisuColors.incompleteBackground,
    onPrimary: SisuColors.incompleteText,
    primaryContainer: SisuColors.getBackgroundColor(isDark),
    onPrimaryContainer: SisuColors.getTextPrimaryColor(isDark),
    // Secondary maps to "completed"
    secondary: SisuColors.completedBackground,
    onSecondary: SisuColors.completedText,
    secondaryContainer:
        isDark ? const Color(0xFF003d3d) : const Color(0xFFb2dfdb),
    onSecondaryContainer: SisuColors.completedText,
    // Tertiary maps to "hidden"
    tertiary: SisuColors.hiddenBackground,
    onTertiary: SisuColors.hiddenText,
    tertiaryContainer:
        isDark ? const Color(0xFF1c252b) : const Color(0xFFe0e0e0),
    onTertiaryContainer: SisuColors.hiddenText,
    // Error maps to "not available"
    error: SisuColors.notAvailableBackground,
    onError: SisuColors.notAvailableText,
    errorContainer:
        isDark ? const Color(0xFF5d1a0a) : const Color(0xFFfce8e6),
    onErrorContainer: SisuColors.notAvailableText,
  );

  final textTheme = TextTheme(
    headlineMedium: TextStyle(
      fontFamily: 'Nunito',
      color: SisuColors.getTextPrimaryColor(isDark),
    ),
    titleMedium: TextStyle(
      fontFamily: 'Nunito',
      color: SisuColors.getTextPrimaryColor(isDark),
    ),
    bodyMedium: TextStyle(
      fontFamily: 'Nunito',
      color: SisuColors.getTextPrimaryColor(isDark),
    ),
  );

  return ThemeData(
    useMaterial3: true,
    fontFamily: 'Nunito',
    colorScheme: colorScheme,
    textTheme: textTheme,
    // Three-layer greys (theme.md §3): scaffold = darkest, card = raised tile.
    scaffoldBackgroundColor: SisuColors.getAppBackground(isDark),
    cardColor: SisuColors.getTileColor(isDark),
    // Tooltips: theme-aware (the default is near-white, too bright on dark).
    tooltipTheme: TooltipThemeData(
      decoration: BoxDecoration(
        color: SisuColors.getTileColor(isDark),
        borderRadius: BorderRadius.circular(6),
      ),
      textStyle: TextStyle(
        color: SisuColors.getTextPrimaryColor(isDark),
        fontSize: 12,
      ),
    ),
    // Snackbars: a dark surface (the M3 default inverts to near-white on dark).
    snackBarTheme: SnackBarThemeData(
      backgroundColor: SisuColors.getListSurface(isDark),
      contentTextStyle: TextStyle(color: SisuColors.getTextPrimaryColor(isDark)),
      actionTextColor: SisuColors.completedText,
      behavior: SnackBarBehavior.floating,
    ),
    // Detail dialogs (#126): raised tile background per theme.md §3, readable
    // title/body text. Buttons below give every AlertDialog action a
    // WCAG-AA-contrast label instead of falling back to M3 defaults derived
    // from the incomplete* colour pair (background/label ratio ~2.9:1).
    dialogTheme: DialogThemeData(
      backgroundColor: SisuColors.getTileColor(isDark),
      titleTextStyle: TextStyle(
        fontFamily: 'Nunito',
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: SisuColors.getTextPrimaryColor(isDark),
      ),
      contentTextStyle: TextStyle(
        fontFamily: 'Nunito',
        color: SisuColors.getTextPrimaryColor(isDark),
      ),
    ),
    // Solid-background dialog actions (Save/Confirm) — dark teal on white
    // clears ~6.8:1 in both themes.
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: SisuColors.completedBackground,
        foregroundColor: SisuColors.dialogButtonOnColor,
        disabledBackgroundColor:
            SisuColors.getTextSecondaryColor(isDark).withValues(alpha: 0.24),
        disabledForegroundColor:
            SisuColors.getTextSecondaryColor(isDark).withValues(alpha: 0.6),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: SisuColors.completedBackground,
        foregroundColor: SisuColors.dialogButtonOnColor,
      ),
    ),
    // Text-only dialog actions (Cancel/etc) — teal label against the dialog
    // surface, ~6.8:1 (light) / ~10.8:1 (dark).
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor:
            isDark ? SisuColors.completedText : SisuColors.completedBackground,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor:
            isDark ? SisuColors.completedText : SisuColors.completedBackground,
        side: BorderSide(
          color:
              isDark ? SisuColors.completedText : SisuColors.completedBackground,
        ),
      ),
    ),
  );
}

// ── Theme Instances ───────────────────────────────────────────────────────────

final ThemeData sisuMateLightTheme =
    createSisuMateTheme(brightness: Brightness.light);

final ThemeData sisuMateDarkTheme =
    createSisuMateTheme(brightness: Brightness.dark);
