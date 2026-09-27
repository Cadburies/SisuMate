import 'package:flutter_test/flutter_test.dart';

import '_reach.dart';

/// Feature Map scripts for `.ai_context/feature_map/home/games/liars_dice*`.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> waitAny(WidgetTester tester, List<String> texts) async {
    for (var i = 0; i < 80 && texts.every((t) => find.text(t).evaluate().isEmpty); i++) {
      await tester.pump(const Duration(milliseconds: 500));
    }
  }

  testWidgets("home/games/liars_dice", (tester) async {
    await reach(tester, 'home/games/liars_dice');
    expect(find.text('Start Game'), findsOneWidget);
    await finish(tester);
  });

  testWidgets("home/games/liars_dice/add_players", (tester) async {
    await reach(tester, 'home/games/liars_dice/add_players');
    expect(find.text('You'), findsOneWidget);
    await finish(tester);
  });

  // #414 regression: leaving a started game used to throw while a
  // non-shaking die created its AnimationController inside dispose().
  testWidgets("home/games/liars_dice/start", (tester) async {
    await reach(tester, 'home/games/liars_dice/start');
    expect(find.text('Add Players (2–10)'), findsNothing);
    await finish(tester);
  });

  testWidgets("home/games/liars_dice/declare", (tester) async {
    await reach(tester, 'home/games/liars_dice/declare');
    await waitAny(tester, ['Roll Dice', 'Accept']);
    expect(find.text('Roll Dice').evaluate().isNotEmpty || find.text('Accept').evaluate().isNotEmpty, isTrue);
    await finish(tester);
  });

  testWidgets("home/games/liars_dice/accept_or_challenge", (tester) async {
    await reach(tester, 'home/games/liars_dice/accept_or_challenge');
    await waitAny(tester, ['Accept', 'Challenge!']);
    expect(find.text('Accept').evaluate().isNotEmpty || find.text('Roll Dice').evaluate().isNotEmpty, isTrue);
    await finish(tester);
  });

  testWidgets("home/games/liars_dice/reset", (tester) async {
    await reach(tester, 'home/games/liars_dice/reset');
    expect(find.text('Add Players (2–10)'), findsOneWidget);
    await finish(tester);
  });
}
