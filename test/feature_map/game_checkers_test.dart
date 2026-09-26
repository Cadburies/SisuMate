import 'package:flutter_test/flutter_test.dart';

import '_reach.dart';

/// Feature Map scripts for `.ai_context/feature_map/home/games/checkers*`.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('home/games/checkers', (tester) async {
    await reach(tester, 'home/games/checkers');
    expect(find.text('Your turn — tap a red piece to select it.'), findsOneWidget);
  });

  testWidgets('home/games/checkers/new_game', (tester) async {
    await reach(tester, 'home/games/checkers/new_game');
    expect(find.text('Your turn — tap a red piece to select it.'), findsOneWidget);
  });
}
