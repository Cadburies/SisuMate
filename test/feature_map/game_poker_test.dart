import 'package:flutter_test/flutter_test.dart';

import '_reach.dart';

/// Feature Map scripts for `.ai_context/feature_map/home/games/poker*`.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('home/games/poker', (tester) async {
    await reach(tester, 'home/games/poker');
    expect(find.text('Bet \$20'), findsOneWidget);
  });

  testWidgets('home/games/poker/check', (tester) async {
    await reach(tester, 'home/games/poker/check');
    await drain(tester);
    expect(find.textContaining('Pot: \$'), findsOneWidget);
  });

  testWidgets('home/games/poker/bet', (tester) async {
    await reach(tester, 'home/games/poker/bet');
    await drain(tester);
    expect(find.textContaining('Pot: \$'), findsOneWidget);
  });

  testWidgets('home/games/poker/fold', (tester) async {
    await reach(tester, 'home/games/poker/fold');
    await drain(tester);
    expect(find.textContaining('AI: \$'), findsOneWidget);
  });

  testWidgets('home/games/poker/draw', (tester) async {
    await reach(tester, 'home/games/poker/draw');
    for (var i = 0; i < 40 && find.textContaining('Draw (').evaluate().isEmpty; i++) {
      await tester.pump(const Duration(milliseconds: 500));
      if (find.text('Call').evaluate().isNotEmpty) await runStep(tester, 'text:Call');
      if (find.text('Check').evaluate().isNotEmpty) await runStep(tester, 'text:Check');
    }
    expect(find.textContaining('Draw ('), findsOneWidget);
    await drain(tester);
  });

  testWidgets('home/games/poker/new_game', (tester) async {
    await reach(tester, 'home/games/poker/new_game');
    expect(find.text('Fold'), findsOneWidget);
  });
}
