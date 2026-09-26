import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '_reach.dart';

/// Feature Map scripts for `.ai_context/feature_map/home/documents*`.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('home/documents', (tester) async {
    await reach(tester, 'home/documents');
    expect(find.text('No documents yet'), findsOneWidget);
  });

  testWidgets('home/documents/add_document', (tester) async {
    await reach(tester, 'home/documents/add_document');
    expect(find.text('Add Document'), findsOneWidget);
  });

  testWidgets('home/documents/add_document [free]', (tester) async {
    await reach(tester, 'home/documents/add_document', tier: 'free');
    expect(find.text('Add Document'), findsNothing);
    expect(find.byType(AlertDialog), findsOneWidget);
  });

  testWidgets('home/documents/document', (tester) async {
    await reach(tester, 'home/documents/document');
    expect(find.text('1 of 1'), findsOneWidget);
    expect(find.text('Insurance'), findsOneWidget);
  });

  testWidgets('home/documents/claim_check', (tester) async {
    await reach(tester, 'home/documents/claim_check');
    expect(find.text('AI: Insurance claim check'), findsOneWidget);
  });
}
