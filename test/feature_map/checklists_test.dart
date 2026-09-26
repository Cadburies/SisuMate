import 'package:flutter_test/flutter_test.dart';
import 'package:sisu_mate/models/models.dart';
import 'package:sisu_mate/providers/checklist_autopilot_provider.dart';
import 'package:sisu_mate/services/suggestion_engine.dart';

import '_reach.dart';

/// Feature Map scripts for `.ai_context/feature_map/home/checklists*`.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const list = 'Last Minute Departure Checks';
  const item = 'Final Weather Check';

  testWidgets('home/checklists', (tester) async {
    await reach(tester, 'home/checklists');
    expect(find.text(list), findsOneWidget);
  });

  testWidgets('home/checklists/search', (tester) async {
    await reach(tester, 'home/checklists/search');
    expect(find.text('Matched: Final Engine Check'), findsOneWidget);
  });

  testWidgets('home/checklists/new_checklist', (tester) async {
    await reach(tester, 'home/checklists/new_checklist');
    expect(find.text('New Checklist'), findsOneWidget);
    await runStep(tester, 'type:Checklist name=Night Watch');
    await runStep(tester, 'text:Create');
    await runStep(tester, 'text:Night Watch'); // scrolls to it and opens it
    expect(find.text('Night Watch'), findsWidgets);
  });

  testWidgets('home/checklists/new_checklist [free]', (tester) async {
    await reach(tester, 'home/checklists', tier: 'free');
    expect(find.byTooltip('Create custom checklist'), findsNothing);
    expect(find.byTooltip('Upgrade to Pro'), findsWidgets);
  });

  testWidgets('home/checklists/filters', (tester) async {
    await reach(tester, 'home/checklists/filters');
    expect(find.text('Show Completed Items'), findsOneWidget);
    expect(find.text('Show Incomplete Items'), findsOneWidget);
  });

  testWidgets('home/checklists/autopilot', (tester) async {
    final group = ChecklistGroup()
      ..supabaseId = 'fm-group'
      ..title = 'Night Passage Checks';
    await reach(tester, 'home/checklists', overrides: [
      checklistAutopilotProvider.overrideWith((ref) => [
            ChecklistAutopilotSuggestion(group: group, reason: 'Departure tomorrow'),
          ]),
    ]);
    expect(find.text('Run before you go'), findsOneWidget);
    expect(find.textContaining('Departure tomorrow'), findsOneWidget);
  });

  testWidgets('home/checklists/checklist', (tester) async {
    await reach(tester, 'home/checklists/checklist');
    expect(find.text(item), findsOneWidget);
  });

  testWidgets('home/checklists/checklist/complete_all', (tester) async {
    await reach(tester, 'home/checklists/checklist/complete_all');
    expect(find.text('Complete All Items?'), findsOneWidget);
  });

  testWidgets('home/checklists/checklist/clear_all', (tester) async {
    await reach(tester, 'home/checklists/checklist/clear_all');
    expect(find.text('Cancel'), findsOneWidget);
  });

  testWidgets('home/checklists/checklist/show_hidden', (tester) async {
    await reach(tester, 'home/checklists/checklist/show_hidden');
    expect(find.text('Show Hidden Items'), findsOneWidget);
  });

  testWidgets('home/checklists/checklist/unhide', (tester) async {
    await reach(tester, 'home/checklists/checklist/unhide');
    expect(find.text(item), findsOneWidget);
  });

  testWidgets('home/checklists/checklist/delete_hidden', (tester) async {
    await reach(tester, 'home/checklists/checklist/delete_hidden');
    expect(find.text(item), findsNothing);
  });
}
