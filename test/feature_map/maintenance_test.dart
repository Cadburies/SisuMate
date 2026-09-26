import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '_reach.dart';

/// Feature Map scripts for `.ai_context/feature_map/home/maintenance*`.
/// The module menu is left out until #403 (drawer header overflow) is fixed.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('home/maintenance', (tester) async {
    await reach(tester, 'home/maintenance');
    expect(find.text('Yanmar 4JH45 - 250-Hour Engine Service'), findsOneWidget);
  });

  testWidgets('home/maintenance/schedule', (tester) async {
    await reach(tester, 'home/maintenance/schedule');
    expect(find.text('Raw Water Pump Service'), findsOneWidget);
  });

  testWidgets('home/maintenance/schedule/add_item', (tester) async {
    await reach(tester, 'home/maintenance/schedule/add_item');
    expect(find.byType(AlertDialog), findsOneWidget);
  });

  testWidgets('home/maintenance/schedule/add_item [free]', (tester) async {
    await reach(tester, 'home/maintenance/schedule', tier: 'free');
    expect(find.byTooltip('Add maintenance item'), findsNothing);
  });

  testWidgets('home/maintenance/schedule/add_spare', (tester) async {
    await reach(tester, 'home/maintenance/schedule/add_spare');
    expect(find.text('Add Inventory Item'), findsOneWidget);
    expect(find.textContaining('Raw Water Pump Service'), findsWidgets);
  });

  testWidgets('home/maintenance/schedule/add_spare [free]', (tester) async {
    await reach(tester, 'home/maintenance/schedule/add_spare', tier: 'free');
    expect(find.text('Add Inventory Item'), findsNothing);
    expect(find.byType(AlertDialog), findsOneWidget);
  });

  testWidgets('home/maintenance/schedule/ai_tools', (tester) async {
    await reach(tester, 'home/maintenance/schedule/ai_tools');
    expect(find.text('Explain this task'), findsOneWidget);
    expect(find.text('Check warranty coverage'), findsOneWidget);
    expect(find.text('Find a compatible part near me'), findsOneWidget);
  });

  testWidgets('home/maintenance/schedule/ai_tools/explain', (tester) async {
    await reach(tester, 'home/maintenance/schedule/ai_tools/explain');
    await runStep(tester, 'wait:AI: Raw Water Pump Service');
    expect(find.text('Go to Settings'), findsOneWidget);
  });

  testWidgets('home/maintenance/schedule/ai_tools/warranty', (tester) async {
    await reach(tester, 'home/maintenance/schedule/ai_tools/warranty');
    expect(find.text('AI: Warranty check'), findsOneWidget);
    expect(find.text('Ask'), findsOneWidget);
  });

  testWidgets('home/maintenance/schedule/ai_tools/part_sourcing', (tester) async {
    await reach(tester, 'home/maintenance/schedule/ai_tools/part_sourcing');
    expect(find.text('AI: Find a compatible part'), findsOneWidget);
  });

  testWidgets('home/maintenance/hours', (tester) async {
    await reach(tester, 'home/maintenance/hours');
    expect(find.text('Engine Hours & Service Log'), findsOneWidget);
  });

  testWidgets('home/maintenance/hours/add_task', (tester) async {
    await reach(tester, 'home/maintenance/hours/add_task');
    expect(find.text('Add Maintenance Task'), findsOneWidget);
    await runStep(tester, 'type:Description=Change impeller');
    await runStep(tester, 'text:Save');
    expect(find.text('Never logged done'), findsOneWidget);
  });

  testWidgets('home/maintenance/hours/triage', (tester) async {
    await reach(tester, 'home/maintenance/hours/triage');
    expect(find.text('Maintenance risk triage'), findsOneWidget);
    expect(find.textContaining('[LOW] Change impeller'), findsOneWidget);
  });
}
