import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// #158: every drawer must carry ProUpgradeSection + AboutSection (About /
/// version info & links) as its last menu items before DrawerFooter, matching
/// the tail pattern every other module drawer already uses. Source-scan
/// rather than widget-pump — these are plain ordering/presence checks across
/// several screens, not behavior worth the provider/auth setup cost per file.
void main() {
  final root = Directory.current.path;

  String read(String relativePath) =>
      File('$root/$relativePath').readAsStringSync();

  /// Asserts ProUpgradeSection appears, AboutSection appears after it, and
  /// DrawerFooter appears after that — i.e. the required tail order.
  void expectProThenAboutThenFooter(String source, {String? label}) {
    final proIndex = source.indexOf('ProUpgradeSection()');
    final aboutIndex = source.indexOf('AboutSection()');
    final footerIndex = source.indexOf('DrawerFooter()');
    expect(proIndex, greaterThanOrEqualTo(0),
        reason: '${label ?? ''} missing ProUpgradeSection');
    expect(aboutIndex, greaterThanOrEqualTo(0),
        reason: '${label ?? ''} missing AboutSection');
    expect(footerIndex, greaterThanOrEqualTo(0),
        reason: '${label ?? ''} missing DrawerFooter');
    expect(proIndex, lessThan(aboutIndex),
        reason: '${label ?? ''} ProUpgradeSection must come before AboutSection');
    expect(aboutIndex, lessThan(footerIndex),
        reason: '${label ?? ''} AboutSection must come before DrawerFooter');
  }

  test('Home drawer has ProUpgradeSection + AboutSection before the footer',
      () {
    expectProThenAboutThenFooter(
      read('lib/ui/home/home_screen.dart'),
      label: 'home_screen.dart',
    );
  });

  test('Weather drawer has ProUpgradeSection + AboutSection before the footer',
      () {
    expectProThenAboutThenFooter(
      read('lib/ui/weather/weather_screen.dart'),
      label: 'weather_screen.dart',
    );
  });

  test('Games drawer has ProUpgradeSection + AboutSection before the footer',
      () {
    expectProThenAboutThenFooter(
      read('lib/ui/games/games_screen.dart'),
      label: 'games_screen.dart',
    );
  });

  test(
      'Shopping item-options drawer has ProUpgradeSection + AboutSection '
      '(was missing AboutSection)', () {
    final source = read('lib/ui/shopping/shopping_screen.dart');
    // The item-options drawer is the 2nd occurrence in this file (the main
    // list drawer already had both).
    final proIndex = source.lastIndexOf('ProUpgradeSection()');
    final aboutIndex = source.lastIndexOf('AboutSection()');
    expect(aboutIndex, greaterThan(proIndex),
        reason: 'shopping_screen.dart item-options drawer: AboutSection '
            'must follow the last ProUpgradeSection');
  });

  test(
      'Bar/Pantry ingredient detail drawer has ProUpgradeSection + '
      'AboutSection (was missing AboutSection)', () {
    expectProThenAboutThenFooter(
      read('lib/ui/components/ingredient_detail_screen.dart'),
      label: 'ingredient_detail_screen.dart',
    );
  });
}
