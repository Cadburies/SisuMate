import 'dart:math' as math;

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sisu_mate/core/colors.dart';
import 'package:sisu_mate/core/di.dart';
import 'package:sisu_mate/data/drift/app_database.dart';
import 'package:sisu_mate/models/models.dart';
import 'package:sisu_mate/ui/checklists/check_page_viewer.dart';

/// #185: the "Uncomplete" action on a completed item was nearly invisible —
/// its icon/text color was set to the *current* (completed/green) state's
/// color, which is exactly the sticky action bar's own background on a
/// completed item. Fix: the action button's background now always hints the
/// state a tap moves *into* (paired with that state's own text token), never
/// the current state.
///
/// A full-screen `meetsGuideline(textContrastGuideline)` scan isn't used
/// here — it also flags pre-existing, unrelated light-theme contrast issues
/// elsewhere on this screen (title-bar status line, description text) that
/// predate this fix and aren't in scope. Instead this asserts directly on
/// the action button: the exact background/text colors it renders with, and
/// that those colors meet WCAG AA contrast.

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
  const itemId = 'item-contrast-1';

  Future<void> seed({required bool isCompleted, bool isHidden = false}) async {
    await db.into(db.checklistItems).insert(
          ChecklistItemsCompanion.insert(
            supabaseId: const Value(itemId),
            groupSupabaseId: const Value('g1'),
            boatSupabaseId: const Value('b1'),
            title: const Value('Check bilge pump'),
            name: const Value('Check bilge pump'),
            isCompleted: Value(isCompleted),
            isHidden: Value(isHidden),
          ),
        );
  }

  ChecklistItem viewerItem({required bool isCompleted, bool isHidden = false}) =>
      ChecklistItem()
        ..supabaseId = itemId
        ..groupSupabaseId = 'g1'
        ..boatSupabaseId = 'b1'
        ..title = 'Check bilge pump'
        ..name = 'Check bilge pump'
        ..isCompleted = isCompleted
        ..isHidden = isHidden;

  Future<void> pumpViewer(
    WidgetTester tester, {
    required bool isCompleted,
    bool isHidden = false,
  }) async {
    final container = ProviderContainer(overrides: [
      appDatabaseProvider.overrideWithValue(db),
      isProProvider.overrideWith((ref) => Stream.value(true)),
    ]);
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: ThemeData(brightness: Brightness.dark),
          home: CheckPageViewer(
            items: [
              viewerItem(isCompleted: isCompleted, isHidden: isHidden)
            ],
            initialIndex: 0,
            groupName: 'Pre-departure',
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
  }

  /// The action button's [Material] fill color and its label [Text] color,
  /// for the button whose label is [label].
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

  testWidgets(
      '"Complete" on an open item previews the completed (destination) '
      'state, not its own current state', (tester) async {
    await seed(isCompleted: false);
    await pumpViewer(tester, isCompleted: false);

    final (bg, text) = actionButtonColors(tester, 'Complete');
    final completedState = SisuColors.itemStateColors(true, ItemListState.stocked);
    expect(bg, completedState.bg,
        reason: 'tapping Complete moves the item into the completed state — '
            'the button should preview that, not the current open state');
    expect(text, completedState.title);
    expect(_contrastRatio(bg, text), greaterThanOrEqualTo(4.5));
  });

  testWidgets(
      '"Uncomplete" on a completed item previews the open (destination) '
      'state, not the completed state it is currently in (#185 regression)',
      (tester) async {
    await seed(isCompleted: true);
    await pumpViewer(tester, isCompleted: true);

    final (bg, text) = actionButtonColors(tester, 'Uncomplete');
    final completedState = SisuColors.itemStateColors(true, ItemListState.stocked);
    final openState = SisuColors.itemStateColors(true, ItemListState.defaults);
    expect(bg, isNot(completedState.bg),
        reason: 'before the fix this was completedBackground — the same '
            'green as the surrounding completed-state action bar, making '
            'the button unreadable');
    expect(bg, openState.bg,
        reason: 'tapping Uncomplete moves the item back to open — the '
            'button should preview that state');
    expect(text, openState.title);
    expect(_contrastRatio(bg, text), greaterThanOrEqualTo(4.5),
        reason: 'button background vs its own label must meet WCAG AA '
            'regardless of what color the surrounding screen happens to be');
  });

  testWidgets(
      '#204: "Hide" on a visible item previews the hidden (destination) '
      'state, not a static color regardless of direction', (tester) async {
    await seed(isCompleted: false);
    await pumpViewer(tester, isCompleted: false);

    final (bg, text) = actionButtonColors(tester, 'Hide');
    final hiddenState = SisuColors.itemStateColors(true, ItemListState.hidden);
    expect(bg, hiddenState.bg);
    expect(text, hiddenState.title);
    expect(_contrastRatio(bg, text), greaterThanOrEqualTo(4.5));
  });

  testWidgets(
      '#204: "Unhide" on a hidden item previews the visible (destination) '
      'state, not the hidden state it is currently in', (tester) async {
    await seed(isCompleted: false, isHidden: true);
    await pumpViewer(tester, isCompleted: false, isHidden: true);

    final (bg, text) = actionButtonColors(tester, 'Unhide');
    final hiddenState = SisuColors.itemStateColors(true, ItemListState.hidden);
    final visibleState =
        SisuColors.itemStateColors(true, ItemListState.defaults);
    expect(bg, isNot(hiddenState.bg),
        reason: 'before the fix Hide and Unhide shared one static color '
            '(SisuColors.hideAction) regardless of direction');
    expect(bg, visibleState.bg);
    expect(text, visibleState.title);
    expect(_contrastRatio(bg, text), greaterThanOrEqualTo(4.5));
  });
}
