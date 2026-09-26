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
}
