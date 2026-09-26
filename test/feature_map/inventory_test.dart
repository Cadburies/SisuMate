import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '_reach.dart';

/// Feature Map scripts for `.ai_context/feature_map/home/inventory*` and
/// `shared/record_detail` (reached through Inventory).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('home/inventory', (tester) async {
    await reach(tester, 'home/inventory');
    expect(find.text('No inventory items yet'), findsOneWidget);
  });

  testWidgets('home/inventory/add_item', (tester) async {
    await reach(tester, 'home/inventory/add_item');
    expect(find.text('Add Inventory Item'), findsOneWidget);
    await runStep(tester, 'type:Name=Spare impeller');
    await runStep(tester, 'text:Save');
    expect(find.text('Qty: 1'), findsOneWidget);
  });

  testWidgets('home/inventory/add_item [free]', (tester) async {
    await reach(tester, 'home/inventory/add_item', tier: 'free');
    expect(find.text('Add Inventory Item'), findsNothing);
    expect(find.byType(AlertDialog), findsOneWidget);
  });

  testWidgets('home/inventory/item', (tester) async {
    await reach(tester, 'home/inventory/item');
    expect(find.text('1 of 1'), findsOneWidget);
    expect(find.text('Used by'), findsOneWidget);
  });

  testWidgets('home/inventory/share_select', (tester) async {
    await reach(tester, 'home/inventory/share_select');
    expect(find.text('0 selected'), findsOneWidget);
    expect(find.byTooltip('Share selected'), findsOneWidget);
  });

  testWidgets('shared/record_detail', (tester) async {
    await reach(tester, 'shared/record_detail');
    expect(find.text('Delete'), findsOneWidget);
    expect(find.text('Edit'), findsOneWidget);
    // Tapping Edit on an inventory item overflows today: #404.
  });
}
