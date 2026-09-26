import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '_reach.dart';

/// Feature Map scripts for `.ai_context/feature_map/launch/*`. The splash and
/// database-problem dialog need a real device (StartupScreen opens the file
/// DB); their host coverage is test/startup_lifecycle_test.dart.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<bool?> seen() async =>
      (await SharedPreferences.getInstance()).getBool('onboarding_seen_v1');

  testWidgets('launch/onboarding', (tester) async {
    await reach(tester, 'launch/onboarding');
    expect(find.text('Welcome to Sisu Mate'), findsOneWidget);
    expect(find.text('Skip'), findsOneWidget);
  });

  testWidgets('launch/onboarding/next', (tester) async {
    await reach(tester, 'launch/onboarding/next');
    expect(find.text('How to use'), findsOneWidget);
  });

  testWidgets('launch/onboarding/skip', (tester) async {
    await reach(tester, 'launch/onboarding/skip');
    expect(find.text('Shopping'), findsOneWidget);
    expect(await tester.runAsync(seen), isTrue);
  });

  testWidgets('launch/onboarding/get_started', (tester) async {
    await reach(tester, 'launch/onboarding/get_started');
    expect(find.text('Shopping'), findsOneWidget);
    expect(await tester.runAsync(seen), isTrue);
  });
}
