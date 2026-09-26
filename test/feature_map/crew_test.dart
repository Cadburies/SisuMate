import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '_reach.dart';

/// Feature Map scripts for `.ai_context/feature_map/home/crew*`.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('home/crew', (tester) async {
    await reach(tester, 'home/crew');
    expect(find.text('No crew members yet'), findsOneWidget);
  });

  testWidgets('home/crew/add_member', (tester) async {
    await reach(tester, 'home/crew/add_member');
    await runStep(tester, 'type:Name=Anna Smith');
    await runStep(tester, 'text:Save');
    expect(find.text('Anna Smith'), findsOneWidget);
  });

  testWidgets('home/crew/add_member [free]', (tester) async {
    await reach(tester, 'home/crew/add_member', tier: 'free');
    expect(find.byType(AlertDialog), findsOneWidget);
    expect(find.widgetWithText(TextField, 'Name'), findsNothing);
  });

  testWidgets('home/crew/member', (tester) async {
    await reach(tester, 'home/crew/member');
    expect(find.text('1 of 1'), findsOneWidget);
    expect(find.text('Role'), findsOneWidget);
  });

  testWidgets('home/crew/share_select', (tester) async {
    await reach(tester, 'home/crew/share_select');
    expect(find.text('0 selected'), findsOneWidget);
  });

  testWidgets('home/crew/travel_safety', (tester) async {
    await reach(tester, 'home/crew/travel_safety');
    expect(find.text('AI: Travel & entry safety'), findsOneWidget);
  });
}
