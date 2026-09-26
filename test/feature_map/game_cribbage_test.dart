import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '_reach.dart';

/// Feature Map scripts for `.ai_context/feature_map/home/games/cribbage*`.
/// Hands are random, so the discard test taps the first two cards.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('home/games/cribbage', (tester) async {
    await reach(tester, 'home/games/cribbage');
    expect(find.text('Your Hand — select 2 to discard'), findsOneWidget);
    expect(find.text('Select 2 more'), findsOneWidget);
  });

  testWidgets('home/games/cribbage/discard', (tester) async {
    await reach(tester, 'home/games/cribbage/discard');
    final row = find.byWidgetPredicate((w) => w.runtimeType.toString() == '_CardRow');
    final cards = find.descendant(of: row, matching: find.byType(GestureDetector));
    await tester.tap(cards.at(0));
    await settle(tester);
    await tester.tap(cards.at(1));
    await settle(tester);
    expect(find.text('Confirm Discard'), findsOneWidget);
    await runStep(tester, 'text:Confirm Discard');
    await drain(tester);
    expect(find.text('Your Hand — select 2 to discard'), findsNothing);
  });

  testWidgets('home/games/cribbage/new_game', (tester) async {
    await reach(tester, 'home/games/cribbage/new_game');
    expect(find.text('Select 2 more'), findsOneWidget);
  });
}
