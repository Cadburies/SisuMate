import 'package:flutter_test/flutter_test.dart';

import '_reach.dart';

/// Feature Map scripts for `.ai_context/feature_map/home/games/uno*`.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('home/games/uno', (tester) async {
    await reach(tester, 'home/games/uno');
    expect(find.text('You — 7 cards'), findsOneWidget);
    await finish(tester);
  });

  testWidgets('home/games/uno/draw', (tester) async {
    await reach(tester, 'home/games/uno/draw');
    expect(find.text('You — 8 cards'), findsOneWidget);
    await finish(tester);
  });

  testWidgets('home/games/uno/play_card', (tester) async {
    await reach(tester, 'home/games/uno/play_card');
    // "Play Card" appears once a hand card is selected (hands are random).
    expect(find.text('Your turn! Play a card or draw.'), findsOneWidget);
    await finish(tester);
  });

  testWidgets('home/games/uno/new_game', (tester) async {
    await reach(tester, 'home/games/uno/new_game');
    expect(find.text('You — 7 cards'), findsOneWidget);
    await finish(tester);
  });
}
