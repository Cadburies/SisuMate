import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '_reach.dart';

/// Feature Map scripts for `.ai_context/feature_map/home/safety*`.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('home/safety', (tester) async {
    await reach(tester, 'home/safety');
    expect(find.text('Day Trip Safety Briefing'), findsOneWidget);
  });

  testWidgets('home/safety/filters', (tester) async {
    await reach(tester, 'home/safety/filters');
    expect(find.text('Show Completed Items'), findsOneWidget);
    expect(find.text('Show Hidden Items'), findsOneWidget);
  });

  testWidgets('home/safety/briefing', (tester) async {
    await reach(tester, 'home/safety/briefing');
    expect(find.text('Sunscreen'), findsOneWidget);
  });

  testWidgets('home/safety/briefing/add_item', (tester) async {
    await reach(tester, 'home/safety/briefing/add_item');
    expect(find.byType(AlertDialog), findsOneWidget);
  });

  testWidgets('home/safety/briefing/add_item [free]', (tester) async {
    await reach(tester, 'home/safety/briefing', tier: 'free');
    expect(find.byTooltip('Add safety item'), findsNothing);
    expect(find.byTooltip('Upgrade to Pro'), findsWidgets);
  });

  testWidgets('home/safety/briefing/compliance_check', (tester) async {
    await reach(tester, 'home/safety/briefing/compliance_check');
    expect(find.text('Safety compliance check'), findsOneWidget);
    expect(find.text('Check offline pack'), findsOneWidget);
  });

  testWidgets('home/safety/briefing/complete_all', (tester) async {
    await reach(tester, 'home/safety/briefing/complete_all');
    expect(find.byType(AlertDialog), findsOneWidget);
  });
}
