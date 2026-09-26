import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '_reach.dart';

/// Feature Map scripts for `.ai_context/feature_map/home/shopping*`.
/// Test names are feature ids (`scripts/fm.sh <id>`); `[free]` = Free variant.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('home/shopping', (tester) async {
    await reach(tester, 'home/shopping');
    expect(find.text('Shopping & Spares'), findsOneWidget);
  });

  testWidgets('home/shopping/add_item', (tester) async {
    await reach(tester, 'home/shopping/add_item');
    expect(find.text('Add Shopping Item'), findsOneWidget);

    await runStep(tester, 'type:Item Name=Impeller');
    await runStep(tester, 'text:Add Item');
    expect(find.text('Impeller added to shopping list'), findsOneWidget);
  });

  testWidgets('home/shopping/add_item [free]', (tester) async {
    await reach(tester, 'home/shopping/add_item', tier: 'free');
    expect(find.text('Sisu Mate Pro Required'), findsOneWidget);
    expect(find.text('Add Shopping Item'), findsNothing);
  });

  testWidgets('home/shopping/add_item [empty name]', (tester) async {
    await reach(tester, 'home/shopping/add_item');
    await runStep(tester, 'text:Add Item');
    expect(find.text('Item name is required'), findsOneWidget);
    expect(find.byType(AlertDialog), findsOneWidget);
  });

  testWidgets('home/shopping/sort', (tester) async {
    await reach(tester, 'home/shopping/sort');
    expect(find.text('Name A-Z'), findsOneWidget);
  });

  testWidgets('home/shopping/buy_before_passage', (tester) async {
    await reach(tester, 'home/shopping/buy_before_passage');
    expect(find.text('Buy before passage'), findsOneWidget);
    expect(find.text('Impeller — Boat-critical (spares)'), findsOneWidget);
  });

  testWidgets('home/shopping/item', (tester) async {
    await reach(tester, 'home/shopping/item');
    expect(find.text('Status: to buy'), findsOneWidget);
    expect(find.text('Bought'), findsOneWidget);
  });

  testWidgets('home/shopping/mark_bought', (tester) async {
    await reach(tester, 'home/shopping/mark_bought');
    expect(find.text('Nothing pending'), findsOneWidget);
  });

  testWidgets('home/shopping/shop_guide', (tester) async {
    await reach(tester, 'home/shopping/shop_guide');
    expect(find.text('Shop: Impeller'), findsOneWidget);
    expect(find.textContaining('Offline shopping guide'), findsOneWidget);
  });

  testWidgets('home/shopping/port_run', (tester) async {
    await reach(tester, 'home/shopping/port_run');
    expect(find.text('Port run · 0 to buy'), findsOneWidget);
  });

  testWidgets('home/shopping/customs_check', (tester) async {
    await reach(tester, 'home/shopping/customs_check');
    expect(find.text('Check offline pack'), findsOneWidget);
  });

  testWidgets('home/shopping/menu', (tester) async {
    await reach(tester, 'home/shopping/menu');
    expect(find.text('Show Hidden Items'), findsOneWidget);
    expect(find.text('Email All Lists'), findsOneWidget);
  });

  testWidgets('home/shopping/menu/complete_run', (tester) async {
    await reach(tester, 'home/shopping/menu/complete_run');
    expect(find.text('Clear bought'), findsOneWidget);
  });
}
