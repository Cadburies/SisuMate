import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '_reach.dart';

/// Authoring aid for `reach:` lines: starts at Home (seeded, Pro), runs the
/// steps in FM_STEPS, then prints every visible text, tooltip and semantics
/// label on screen. No-op in the suite (FM_STEPS empty).
///
///   flutter test test/feature_map/explore_test.dart \
///     --dart-define='FM_STEPS=text:Checklists > text:Last Minute Departure Checks'
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const steps = String.fromEnvironment('FM_STEPS');
  const tier = String.fromEnvironment('FM_TIER', defaultValue: 'pro');

  testWidgets('explore', (tester) async {
    await reach(tester, 'home', tier: tier);
    for (final s in steps.split(' > ').where((s) => s.trim().isNotEmpty)) {
      await runStep(tester, s.trim());
    }
    final seen = <String>{};
    void add(String kind, String? v) {
      if (v != null && v.trim().isNotEmpty) seen.add('$kind:${v.trim()}');
    }

    for (final e in find.byType(Text).hitTestable().evaluate()) {
      add('text', (e.widget as Text).data);
    }
    for (final e in find.byType(Tooltip).hitTestable().evaluate()) {
      add('tip', (e.widget as Tooltip).message);
    }
    for (final e in find.byType(Semantics).hitTestable().evaluate()) {
      add('label', (e.widget as Semantics).properties.label);
    }
    // ignore: avoid_print
    print('FM_EXPLORE after "$steps":\n${seen.join('\n')}');
  }, skip: steps.isEmpty);
}
