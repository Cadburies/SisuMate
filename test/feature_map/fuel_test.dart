import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '_reach.dart';

/// Feature Map scripts for `.ai_context/feature_map/home/fuel*`.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('home/fuel', (tester) async {
    await reach(tester, 'home/fuel');
    expect(find.text('No entries yet'), findsOneWidget);
  });

  testWidgets('home/fuel/add_entry', (tester) async {
    await reach(tester, 'home/fuel/add_entry');
    expect(find.text('Add Entry'), findsOneWidget);
  });

  testWidgets('home/fuel/add_entry [free]', (tester) async {
    await reach(tester, 'home/fuel/add_entry', tier: 'free');
    expect(find.text('Add Entry'), findsNothing);
    expect(find.byType(AlertDialog), findsOneWidget);
  });

  testWidgets('home/fuel/burn_range', (tester) async {
    await reach(tester, 'home/fuel/burn_range');
    expect(find.text('Fuel · unknown — log another fill'), findsOneWidget);
  });

  testWidgets('home/fuel/entry', (tester) async {
    await reach(tester, 'home/fuel/entry');
    expect(find.text('Marina fill • 40 L'), findsWidgets);
    expect(find.text('1 of 1'), findsOneWidget);
  });
}
