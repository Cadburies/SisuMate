import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sisu_mate/models/models.dart';
import 'package:sisu_mate/ui/maintenance/maintenance_hours_screen.dart';

Future<void> _pump(
  WidgetTester tester, {
  required void Function(MaintenanceTask) onSave,
}) {
  return tester.pumpWidget(MaterialApp(
    home: Scaffold(
      body: AddEditMaintenanceTaskDialog(onSave: onSave),
    ),
  ));
}

void main() {
  group('AddEditMaintenanceTaskDialog', () {
    testWidgets('saves a new task with description and interval hours',
        (tester) async {
      MaintenanceTask? saved;
      await _pump(tester, onSave: (t) => saved = t);

      await tester.enterText(
          find.widgetWithText(TextFormField, 'Description'),
          'Replace impeller');
      await tester.enterText(
          find.widgetWithText(TextFormField, 'Interval (engine hours)'),
          '500');
      await tester.tap(find.text('Save'));
      await tester.pump();

      expect(saved, isNotNull);
      expect(saved!.description, 'Replace impeller');
      expect(saved!.intervalHours, 500);
    });

    testWidgets('does not call onSave when description is empty',
        (tester) async {
      var saveCalled = false;
      await _pump(tester, onSave: (_) => saveCalled = true);

      await tester.tap(find.text('Save'));
      await tester.pump();

      expect(saveCalled, isFalse);
    });

    testWidgets('does not call onSave when interval hours is not a number',
        (tester) async {
      var saveCalled = false;
      await _pump(tester, onSave: (_) => saveCalled = true);

      await tester.enterText(
          find.widgetWithText(TextFormField, 'Description'), 'Check rig');
      await tester.enterText(
          find.widgetWithText(TextFormField, 'Interval (engine hours)'),
          'abc');
      await tester.tap(find.text('Save'));
      await tester.pump();

      expect(saveCalled, isFalse);
    });
  });
}
