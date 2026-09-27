import 'package:flutter_test/flutter_test.dart';

import '_reach.dart';

/// Feature Map scripts for `.ai_context/feature_map/home/games/yatzy*`.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('home/games/yatzy', (tester) async {
    await reach(tester, 'home/games/yatzy');
    expect(find.text('Rolls left: 3'), findsOneWidget);
    await finish(tester);
  });

  testWidgets('home/games/yatzy/roll', (tester) async {
    await reach(tester, 'home/games/yatzy/roll');
    expect(find.text('Rolls left: 2'), findsOneWidget);
    await finish(tester);
  });

  testWidgets('home/games/yatzy/score', (tester) async {
    await reach(tester, 'home/games/yatzy/score');
    await drain(tester);
    expect(find.text('Rolls left: 2'), findsNothing);
    await finish(tester);
  });

  testWidgets('home/games/yatzy/new_game', (tester) async {
    await reach(tester, 'home/games/yatzy/new_game');
    expect(find.text('Rolls left: 3'), findsOneWidget);
    await finish(tester);
  });
}
