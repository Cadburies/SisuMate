import 'package:flutter_test/flutter_test.dart';

import '_reach.dart';

/// Feature Map scripts for `.ai_context/feature_map/home/polar*`.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('home/polar', (tester) async {
    await reach(tester, 'home/polar');
    expect(find.text('No active boat — set one in Settings.'), findsOneWidget);
  });

  testWidgets('home/polar/diagram', (tester) async {
    await reach(tester, 'home/polar/diagram');
    expect(find.textContaining('Measured coverage: 0%'), findsOneWidget);
    expect(find.text('Reset all'), findsOneWidget);
  });
}
