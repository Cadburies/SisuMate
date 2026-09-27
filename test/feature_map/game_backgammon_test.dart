import 'package:flutter_test/flutter_test.dart';

import '_reach.dart';

/// Feature Map scripts for `.ai_context/feature_map/home/games/backgammon*`.
/// Dice are random, so tests assert state text patterns, not exact rolls.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('home/games/backgammon', (tester) async {
    await reach(tester, 'home/games/backgammon');
    expect(find.text('Roll Dice'), findsOneWidget);
    await finish(tester);
  });

  testWidgets('home/games/backgammon/roll', (tester) async {
    await reach(tester, 'home/games/backgammon/roll');
    expect(find.textContaining('Select a piece to move'), findsOneWidget);
    await finish(tester);
  });

  testWidgets('home/games/backgammon/double', (tester) async {
    await reach(tester, 'home/games/backgammon/double');
    expect(find.textContaining('Double offered'), findsOneWidget);
    await finish(tester);
  });

  testWidgets('home/games/backgammon/coach', (tester) async {
    await reach(tester, 'home/games/backgammon/coach');
    expect(find.text('Hint'), findsOneWidget);
    await finish(tester);
  });

  testWidgets('home/games/backgammon/practice', (tester) async {
    await reach(tester, 'home/games/backgammon/practice');
    expect(find.byTooltip('Practice on (review after your turn)'), findsOneWidget);
    await finish(tester);
  });

  testWidgets('home/games/backgammon/new_game', (tester) async {
    await reach(tester, 'home/games/backgammon/new_game');
    expect(find.text('Roll Dice'), findsOneWidget);
    await finish(tester);
  });
}
