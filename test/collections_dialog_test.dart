import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sisu_mate/models/models.dart';
import 'package:sisu_mate/ui/collections/collections_screen.dart';

Future<void> _pump(
  WidgetTester tester, {
  RecipeCollection? existing,
  required Future<void> Function(String name) onSave,
}) {
  return tester.pumpWidget(MaterialApp(
    home: Scaffold(
      body: AddEditCollectionDialog(existing: existing, onSave: onSave),
    ),
  ));
}

void main() {
  group('AddEditCollectionDialog', () {
    testWidgets('creates a collection when name is provided', (tester) async {
      String? savedName;
      await _pump(tester, onSave: (n) async => savedName = n);

      await tester.enterText(
          find.widgetWithText(TextField, 'Name'), 'Boat Party Menu');
      await tester.tap(find.text('Create'));
      await tester.pump();

      expect(savedName, 'Boat Party Menu');
    });

    testWidgets('does not call onSave when name is empty', (tester) async {
      var called = false;
      await _pump(tester, onSave: (_) async => called = true);

      await tester.tap(find.text('Create'));
      await tester.pump();

      expect(called, isFalse);
    });

    testWidgets('renames an existing collection', (tester) async {
      final existing = RecipeCollection()..name = 'Old Name';

      String? savedName;
      await _pump(
        tester,
        existing: existing,
        onSave: (n) async => savedName = n,
      );

      expect(find.text('Rename Collection'), findsOneWidget);
      expect(find.text('Old Name'), findsOneWidget);

      await tester.enterText(
          find.widgetWithText(TextField, 'Name'), 'New Name');
      await tester.tap(find.text('Save'));
      await tester.pump();

      expect(savedName, 'New Name');
    });
  });
}
