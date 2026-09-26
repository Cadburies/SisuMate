import 'package:flutter_test/flutter_test.dart';

import '_reach.dart';

/// Feature Map scripts for chrome shared by every module:
/// `shared/title_bar`, `shared/import_export*`, `shared/paywall`.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('shared/title_bar', (tester) async {
    await reach(tester, 'shared/title_bar');
    expect(find.text('No Boat • Pro • Online'), findsOneWidget);
    await runStep(tester, 'tip:Back');
    expect(find.text('Ready for passage'), findsOneWidget);
  });

  testWidgets('shared/title_bar [free]', (tester) async {
    await reach(tester, 'shared/title_bar', tier: 'free');
    expect(find.textContaining('No Boat • Free'), findsOneWidget);
  });

  testWidgets('shared/import_export', (tester) async {
    await reach(tester, 'shared/import_export');
    expect(find.text('Import from file'), findsOneWidget);
    expect(find.text('Export to file'), findsOneWidget);
  });

  testWidgets('shared/import_export/paste_messy_list', (tester) async {
    await reach(tester, 'shared/import_export/paste_messy_list');
    expect(find.text('AI: Paste messy list'), findsOneWidget);
    expect(find.text('Parse'), findsOneWidget);
  });

  testWidgets('shared/import_export/paste_messy_list [free]', (tester) async {
    await reach(tester, 'shared/import_export/paste_messy_list', tier: 'free');
    expect(find.text('Upgrade to Sisu Mate Pro'), findsOneWidget);
  });

  testWidgets('shared/import_export/view_example', (tester) async {
    await reach(tester, 'shared/import_export/view_example');
    expect(find.text('Shopping — example'), findsOneWidget);
  });

  testWidgets('shared/paywall', (tester) async {
    await reach(tester, 'shared/paywall');
    expect(find.text('Upgrade to Sisu Mate Pro'), findsOneWidget);
  });
}
