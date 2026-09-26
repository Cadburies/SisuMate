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
}
