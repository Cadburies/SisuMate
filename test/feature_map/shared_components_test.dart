import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '_reach.dart';

/// Feature Map scripts for `.ai_context/feature_map/shared/*` (components used
/// by many modules, reached through one representative module).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const checklist = 'Last Minute Departure Checks';
  const item = 'Final Weather Check';
  const ingredient = 'Aged Balsamic Vinegar';

  /// Reveals a row's swipe pane without tapping an action.
  Future<void> reveal(WidgetTester tester, String row, Offset by) async {
    await tester.drag(find.text(row).first, by);
    await settle(tester);
  }

  testWidgets('shared/swipe/complete', (tester) async {
    await reach(tester, 'shared/swipe/complete');
    await reveal(tester, item, const Offset(-300, 0));
    expect(find.text('Uncomplete'), findsOneWidget);
  });

  testWidgets('shared/swipe/complete [free]', (tester) async {
    await reach(tester, 'shared/swipe/complete', tier: 'free');
    expect(find.text('Marking items complete requires Sisu Pro'), findsOneWidget);
  });

  testWidgets('shared/swipe/hide', (tester) async {
    await reach(tester, 'shared/swipe/hide');
    expect(find.text(item), findsNothing);
    expect(find.text(checklist), findsOneWidget);
  });

  testWidgets('shared/swipe/add_to_shopping', (tester) async {
    await reach(tester, 'shared/swipe/add_to_shopping');
    expect(find.textContaining('On shopping list'), findsOneWidget);
  });

  testWidgets('shared/swipe/in_stock', (tester) async {
    await reach(tester, 'shared/swipe/in_stock');
    await reveal(tester, ingredient, const Offset(-300, 0));
    expect(find.text('Remove'), findsOneWidget);
  });

  testWidgets('shared/check_page_viewer', (tester) async {
    await reach(tester, 'shared/check_page_viewer');
    expect(find.text('$checklist · 2 of 17'), findsOneWidget);
    expect(find.text('Status: open'), findsOneWidget);
  });

  testWidgets('shared/check_page_viewer/complete', (tester) async {
    await reach(tester, 'shared/check_page_viewer/complete');
    expect(find.text('Status: completed'), findsOneWidget);
    expect(find.text('Uncomplete'), findsOneWidget);
  });

  testWidgets('shared/check_page_viewer/complete [free]', (tester) async {
    await reach(tester, 'shared/check_page_viewer/complete', tier: 'free');
    expect(find.text('Status: completed'), findsOneWidget);
    expect(find.textContaining('Free preview:'), findsOneWidget);
  });

  testWidgets('shared/check_page_viewer/edit', (tester) async {
    await reach(tester, 'shared/check_page_viewer/edit');
    expect(find.text('Save'), findsOneWidget);
    expect(find.text('Cancel'), findsOneWidget);
  });

  testWidgets('shared/check_page_viewer/change_photo', (tester) async {
    await reach(tester, 'shared/check_page_viewer/change_photo');
    expect(find.text('Camera'), findsOneWidget);
    expect(find.text('Gallery'), findsOneWidget);
  });

  testWidgets('shared/dialogs/add_checklist_item', (tester) async {
    await reach(tester, 'shared/dialogs/add_checklist_item');
    expect(find.byType(AlertDialog), findsOneWidget);
    expect(find.text('Add'), findsOneWidget);
  });

  testWidgets('shared/dialogs/add_checklist_item [free]', (tester) async {
    await reach(tester, 'shared/check_page_viewer', tier: 'free', steps: 2);
    expect(find.byTooltip('Upgrade to Pro'), findsWidgets);
    expect(find.byTooltip('Add checklist item'), findsNothing);
  });

  testWidgets('shared/ingredient_detail', (tester) async {
    await reach(tester, 'shared/ingredient_detail');
    expect(find.text('My Pantry · 1 of 243'), findsOneWidget);
  });
}
