import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '_reach.dart';

/// Feature Map scripts for `.ai_context/feature_map/home/drawer/settings*`.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('home/drawer/settings', (tester) async {
    await reach(tester, 'home/drawer/settings');
    expect(find.text('Active Boat'), findsOneWidget);
    expect(find.text('Units'), findsOneWidget);
  });

  testWidgets('home/drawer/settings/active_boat', (tester) async {
    await reach(tester, 'home/drawer/settings/active_boat');
    expect(find.text('My Boat • Pro • Online'), findsOneWidget);
    expect(find.text('AI API Keys'), findsOneWidget);
  });

  testWidgets('home/drawer/settings/ai_keys', (tester) async {
    await reach(tester, 'home/drawer/settings/ai_keys');
    expect(find.text('Anthropic (Claude)'), findsOneWidget);
    expect(find.text('Share with crew'), findsWidgets);
  });

  testWidgets('home/drawer/settings/boat_polar', (tester) async {
    await reach(tester, 'home/drawer/settings/boat_polar');
    expect(find.text('Under-sail samples stored: 0'), findsOneWidget);
    expect(find.text('Improve offline'), findsOneWidget);
  });

  testWidgets('home/drawer/settings/theme', (tester) async {
    await reach(tester, 'home/drawer/settings/theme');
    expect(find.text('Light Theme'), findsOneWidget);
  });

  testWidgets('home/drawer/settings/units', (tester) async {
    await reach(tester, 'home/drawer/settings/units');
    expect(find.text('US'), findsOneWidget);
  });

  testWidgets('home/drawer/settings/instruments', (tester) async {
    await reach(tester, 'home/drawer/settings/instruments');
    expect(find.text('PredictWind DataHub'), findsOneWidget);
  });

  testWidgets('home/drawer/settings/crash_log', (tester) async {
    await reach(tester, 'home/drawer/settings/crash_log');
    for (var i = 0; i < 30 && find.textContaining('Nothing to upload').evaluate().isEmpty; i++) {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.textContaining('Nothing to upload'), findsOneWidget);
  });

  testWidgets('home/drawer/settings/factory_reset', (tester) async {
    await reach(tester, 'home/drawer/settings/factory_reset');
    expect(find.text('Reset'), findsOneWidget);
  });

  testWidgets('home/drawer/settings/email_sharing', (tester) async {
    await reach(tester, 'home/drawer/settings/email_sharing');
    expect(find.text('Skipper Sam'), findsOneWidget);
  });

  testWidgets('home/drawer/settings/sign_in', (tester) async {
    await reach(tester, 'home/drawer/settings/sign_in');
    expect(find.text('Boat account'), findsOneWidget);
    expect(find.text('Join a boat'), findsOneWidget);
    expect(find.text('Send Magic Link'), findsNothing);
  });

  testWidgets('home/drawer/settings/ais_alarm', (tester) async {
    await reach(tester, 'home/drawer/settings/ais_alarm');
    expect(find.widgetWithText(SwitchListTile, 'AIS collision alarm'), findsOneWidget);
  });

  testWidgets('home/drawer/settings/legal', (tester) async {
    const channel = MethodChannel('plugins.flutter.io/url_launcher');
    final launched = <String>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      if (call.method == 'launch') launched.add((call.arguments as Map)['url'] as String);
      return true;
    });
    addTearDown(() => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null));
    await reach(tester, 'home/drawer/settings/legal');
    expect(launched, ['https://cadburies.github.io/sisumate-legal/privacy-policy.html']);
  });

  testWidgets('home/drawer/settings/licences', (tester) async {
    await reach(tester, 'home/drawer/settings/licences');
    expect(find.byType(LicensePage), findsOneWidget);
    expect(find.text('\u00a9 2026 Frik Olivier. Apache License 2.0.'), findsOneWidget);
  });
}
