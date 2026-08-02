import 'dart:math' as math;

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sisu_mate/core/colors.dart';
import 'package:sisu_mate/core/di.dart';
import 'package:sisu_mate/data/drift/app_database.dart';
import 'package:sisu_mate/models/models.dart';
import 'package:sisu_mate/ui/shopping/shopping_screen.dart';

/// #204: the Bought/Unbuy and Hide/Unhide action buttons on the shopping
/// item detail screen used one static color regardless of direction
/// (completedBackground for both Bought and Unbuy; SisuColors.hideAction for
/// both Hide and Unhide) — same class of bug #185 fixed for
/// Complete/Uncomplete on check_page_viewer.dart.

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

  ShoppingItem item({required bool isBought, bool isHidden = false}) =>
      ShoppingItem()
        ..supabaseId = 'item-1'
        ..categorySupabaseId = 'cat-1'
        ..name = 'Fenders'
        ..isBought = isBought
        ..isHidden = isHidden;

  Future<void> pumpDetail(
    WidgetTester tester, {
    required bool isBought,
    bool isHidden = false,
  }) async {
    final container = ProviderContainer(overrides: [
      appDatabaseProvider.overrideWithValue(db),
    ]);
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: ThemeData(brightness: Brightness.dark),
          home: ShoppingItemDetailScreen(
            items: [item(isBought: isBought, isHidden: isHidden)],
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

  testWidgets('"Bought" previews the stocked (destination) state',
      (tester) async {
    await pumpDetail(tester, isBought: false);

    final (bg, text) = actionButtonColors(tester, 'Bought');
    final stocked = SisuColors.itemStateColors(true, ItemListState.stocked);
    expect(bg, stocked.bg);
    expect(text, stocked.title);
    expect(_contrastRatio(bg, text), greaterThanOrEqualTo(4.5));
  });

  testWidgets(
      '"Unbuy" previews the shopping-list (destination) state, not the '
      'stocked state it is currently in', (tester) async {
    await pumpDetail(tester, isBought: true);

    final (bg, text) = actionButtonColors(tester, 'Unbuy');
    final stocked = SisuColors.itemStateColors(true, ItemListState.stocked);
    final shopping = SisuColors.itemStateColors(true, ItemListState.shopping);
    expect(bg, isNot(stocked.bg),
        reason: 'before the fix this was always completedBackground, even '
            'for Unbuy');
    expect(bg, shopping.bg);
    expect(text, shopping.title);
    expect(_contrastRatio(bg, text), greaterThanOrEqualTo(4.5));
  });

  testWidgets('"Hide" previews the hidden (destination) state',
      (tester) async {
    await pumpDetail(tester, isBought: false);

    final (bg, text) = actionButtonColors(tester, 'Hide');
    final hidden = SisuColors.itemStateColors(true, ItemListState.hidden);
    expect(bg, hidden.bg);
    expect(text, hidden.title);
    expect(_contrastRatio(bg, text), greaterThanOrEqualTo(4.5));
  });

  testWidgets(
      '"Unhide" previews the shopping-list (destination) state, not the '
      'hidden state it is currently in', (tester) async {
    await pumpDetail(tester, isBought: false, isHidden: true);

    final (bg, text) = actionButtonColors(tester, 'Unhide');
    final hidden = SisuColors.itemStateColors(true, ItemListState.hidden);
    final shopping = SisuColors.itemStateColors(true, ItemListState.shopping);
    expect(bg, isNot(hidden.bg),
        reason: 'before the fix Hide and Unhide shared one static color '
            '(SisuColors.hideAction) regardless of direction');
    expect(bg, shopping.bg);
    expect(text, shopping.title);
    expect(_contrastRatio(bg, text), greaterThanOrEqualTo(4.5));
  });
}
