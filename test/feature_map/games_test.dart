import 'package:flutter_test/flutter_test.dart';

import '_reach.dart';

/// Feature Map scripts for `.ai_context/feature_map/home/games*` (hub, lobby,
/// help). LAN hosting/joining itself needs two devices.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('#411: leaving an untouched lobby does not read ref in dispose', (tester) async {
    await reach(tester, 'home');
    await runStep(tester, 'text:Games');
    await runStep(tester, 'text:Multiplayer Mode');
    await runStep(tester, 'text:Dudo');
    expect(find.text('Host Game'), findsOneWidget);
    await runStep(tester, 'tip:Back');
    expect(find.text('Multiplayer Mode'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('home/games', (tester) async {
    await reach(tester, 'home/games');
    expect(find.text('Dudo'), findsOneWidget);
    expect(find.byTooltip('Multiplayer ready: Dudo'), findsOneWidget);
  });

  testWidgets('home/games/multiplayer', (tester) async {
    await reach(tester, 'home/games/multiplayer');
    await runStep(tester, 'text:Solitaire');
    expect(find.text('Solo only'), findsOneWidget);
  });

  testWidgets('home/games/lobby', (tester) async {
    await reach(tester, 'home/games/lobby');
    expect(find.text('Host Game'), findsOneWidget);
    expect(find.text('Join a Game'), findsOneWidget);
  });

  testWidgets('home/games/help', (tester) async {
    await reach(tester, 'home/games/help');
    expect(find.text('How a Turn Works'), findsOneWidget);
  });
}
