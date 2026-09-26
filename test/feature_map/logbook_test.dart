import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '_reach.dart';

/// Feature Map scripts for `.ai_context/feature_map/home/logbook*`.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('home/logbook', (tester) async {
    await reach(tester, 'home/logbook');
    expect(find.text('No log entries'), findsOneWidget);
  });

  testWidgets('home/logbook/add_entry', (tester) async {
    await reach(tester, 'home/logbook/add_entry');
    expect(find.text('New Log Entry'), findsOneWidget);
    await runStep(tester, 'type:Notes=Anchored in Saldanha Bay');
    await runStep(tester, 'text:Save');
    expect(find.text('Anchored in Saldanha Bay'), findsOneWidget);
  });

  testWidgets('home/logbook/add_entry [free]', (tester) async {
    await reach(tester, 'home/logbook/add_entry', tier: 'free');
    expect(find.text('New Log Entry'), findsNothing);
    expect(find.byType(AlertDialog), findsOneWidget);
  });

  testWidgets('home/logbook/entry', (tester) async {
    await reach(tester, 'home/logbook/entry');
    expect(find.textContaining('Log Entry - '), findsOneWidget);
    expect(find.text('Delete'), findsOneWidget);
  });

  testWidgets('home/logbook/parse_entry', (tester) async {
    await reach(tester, 'home/logbook/parse_entry');
    expect(find.text('AI: Parse Log Entry'), findsOneWidget);
    expect(find.text('Parse offline'), findsOneWidget);
  });

  testWidgets('home/logbook/recurring_issues', (tester) async {
    await reach(tester, 'home/logbook/recurring_issues');
    expect(find.text('Recurring Issues'), findsOneWidget);
    expect(find.textContaining('Not enough log or maintenance notes'), findsOneWidget);
  });
}
