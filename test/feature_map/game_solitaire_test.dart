import 'package:flutter_test/flutter_test.dart';

import '_reach.dart';

/// Feature Map scripts for `.ai_context/feature_map/home/games/solitaire*`.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('home/games/solitaire', (tester) async {
    await reach(tester, 'home/games/solitaire');
    expect(find.text('24'), findsOneWidget);
    expect(find.text('0mv'), findsOneWidget);
    await finish(tester);
  });

  testWidgets('home/games/solitaire/draw', (tester) async {
    await reach(tester, 'home/games/solitaire/draw');
    expect(find.text('23'), findsOneWidget);
    await finish(tester);
  });

  testWidgets('home/games/solitaire/hint', (tester) async {
    await reach(tester, 'home/games/solitaire/hint');
    expect(find.byTooltip('Hide hints'), findsOneWidget);
    await finish(tester);
  });

  testWidgets('home/games/solitaire/new_game', (tester) async {
    await reach(tester, 'home/games/solitaire/new_game');
    expect(find.text('24'), findsOneWidget);
    await finish(tester);
  });
}
