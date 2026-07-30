import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sisu_mate/core/theme.dart';

void main() {
  group('ThemeModeNotifier', () {
    test('defaults to dark (theme.md §1)', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      expect(container.read(themeModeProvider), ThemeMode.dark);
    });

    test('restoreTheme(false) switches to light without persisting', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(themeModeProvider.notifier).restoreTheme(false);
      expect(container.read(themeModeProvider), ThemeMode.light);
    });
  });
}
