import 'dart:math' as math;

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sisu_mate/core/colors.dart';
import 'package:sisu_mate/core/di.dart';
import 'package:sisu_mate/data/drift/app_database.dart';
import 'package:sisu_mate/models/models.dart';
import 'package:sisu_mate/ui/components/ingredient_detail_screen.dart';

/// #204: the My Bar / My Pantry "In stock"/"Remove" action button always
/// used completedBackground (green), even for "Remove" — same class of bug
/// #185 fixed for Complete/Uncomplete on check_page_viewer.dart.

double _srgbToLinear(double c) =>
    c <= 0.03928 ? c / 12.92 : math.pow((c + 0.055) / 1.055, 2.4).toDouble();

double _relativeLuminance(Color c) {
  final r = _srgbToLinear(c.r);
  final g = _srgbToLinear(c.g);
  final b = _srgbToLinear(c.b);
  return 0.2126 * r + 0.7152 * g + 0.0722 * b;
}

double _contrastRatio(Color a, Color b) {
  final la = _relativeLuminance(a) + 0.05;
  final lb = _relativeLuminance(b) + 0.05;
  return la > lb ? la / lb : lb / la;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;

  Future<void> pumpDetail(WidgetTester tester, {required bool inMyBar}) async {
    final container = ProviderContainer(overrides: [
      appDatabaseProvider.overrideWithValue(db),
    ]);
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: ThemeData(brightness: Brightness.dark),
          home: IngredientDetailScreen.bar(
            items: [
              BarIngredient()
                ..supabaseId = 'ing-1'
                ..name = 'Gin'
                ..inMyBar = inMyBar,
            ],
            initialIndex: 0,
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
  }

  (Color background, Color textColor) actionButtonColors(
    WidgetTester tester,
    String label,
  ) {
    final textFinder = find.text(label);
    final textWidget = tester.widget<Text>(textFinder);
    final material = tester.widget<Material>(
      find.ancestor(of: textFinder, matching: find.byType(Material)).first,
    );
    return (material.color!, textWidget.style!.color!);
  }

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async => db.close());

  testWidgets('"In stock" previews the stocked (destination) state',
      (tester) async {
    await pumpDetail(tester, inMyBar: false);

    final (bg, text) = actionButtonColors(tester, 'In stock');
    final stocked = SisuColors.itemStateColors(true, ItemListState.stocked);
    expect(bg, stocked.bg);
    expect(text, stocked.title);
    expect(_contrastRatio(bg, text), greaterThanOrEqualTo(4.5));
  });

  testWidgets(
      '"Remove" previews the default (destination) state, not the stocked '
      'state it is currently in', (tester) async {
    await pumpDetail(tester, inMyBar: true);

    final (bg, text) = actionButtonColors(tester, 'Remove');
    final stocked = SisuColors.itemStateColors(true, ItemListState.stocked);
    final defaults = SisuColors.itemStateColors(true, ItemListState.defaults);
    expect(bg, isNot(stocked.bg),
        reason: 'before the fix this was always completedBackground, even '
            'for Remove');
    expect(bg, defaults.bg);
    expect(text, defaults.title);
    expect(_contrastRatio(bg, text), greaterThanOrEqualTo(4.5));
  });
}
