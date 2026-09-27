import 'package:flutter_test/flutter_test.dart';

import '_reach.dart';

/// Feature Map scripts for `.ai_context/feature_map/home/games/dudo*`.
/// Who starts is rolled at random, so the bid test waits for its turn.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('home/games/dudo', (tester) async {
    await reach(tester, 'home/games/dudo');
    expect(find.text('Start Game'), findsOneWidget);
    await finish(tester);
  });

  testWidgets('home/games/dudo/add_players', (tester) async {
    await reach(tester, 'home/games/dudo/add_players');
    expect(find.text('You'), findsOneWidget);
    expect(find.textContaining('AI '), findsWidgets);
    await finish(tester);
  });

  testWidgets('home/games/dudo/start', (tester) async {
    await reach(tester, 'home/games/dudo/start');
    expect(find.text('Add Players (2–6)'), findsNothing);
    await finish(tester);
  });

  testWidgets('home/games/dudo/bid', (tester) async {
    await reach(tester, 'home/games/dudo/bid');
    for (var i = 0; i < 60 && find.text('Dudo').evaluate().isEmpty; i++) {
      await tester.pump(const Duration(milliseconds: 500));
    }
    // "Dudo" labels the table; the action buttons appear on your turn.
    for (var i = 0; i < 60 && find.text('Bid').evaluate().isEmpty && find.text('Raise').evaluate().isEmpty; i++) {
      await tester.pump(const Duration(milliseconds: 500));
    }
    expect(find.text('Dudo!').evaluate().isNotEmpty || find.text('Bid').evaluate().isNotEmpty, isTrue);
    await finish(tester);
  });

  testWidgets('home/games/dudo/reset', (tester) async {
    await reach(tester, 'home/games/dudo/reset');
    expect(find.text('Add Players (2–6)'), findsOneWidget);
    await finish(tester);
  });
}
