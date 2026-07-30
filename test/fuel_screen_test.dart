import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sisu_mate/models/models.dart';
import 'package:sisu_mate/ui/fuel/fuel_screen.dart';

Future<void> _pump(
  WidgetTester tester, {
  FuelLogEntry? existing,
  required void Function(FuelLogEntry) onSave,
}) {
  return tester.pumpWidget(MaterialApp(
    home: Scaffold(
      body: AddEditFuelEntryDialog(existing: existing, onSave: onSave),
    ),
  ));
}

void main() {
  group('AddEditFuelEntryDialog', () {
    testWidgets('saves a new fuel entry with the default type', (tester) async {
      FuelLogEntry? saved;
      await _pump(tester, onSave: (e) => saved = e);

      await tester.enterText(
          find.widgetWithText(TextFormField, 'Volume (L)'), '40');
      await tester.tap(find.text('Save'));
      await tester.pump();

      expect(saved, isNotNull);
      expect(saved!.type, 'Fuel');
      expect(saved!.liters, 40);
    });

    testWidgets('does not call onSave when the volume field is empty',
        (tester) async {
      var saveCalled = false;
      await _pump(tester, onSave: (_) => saveCalled = true);

      await tester.tap(find.text('Save'));
      await tester.pump();

      expect(saveCalled, isFalse);
    });

    testWidgets('does not call onSave when the volume is not a number',
        (tester) async {
      var saveCalled = false;
      await _pump(tester, onSave: (_) => saveCalled = true);

      await tester.enterText(
          find.widgetWithText(TextFormField, 'Volume (L)'), 'abc');
      await tester.tap(find.text('Save'));
      await tester.pump();

      expect(saveCalled, isFalse);
    });

    testWidgets('pre-fills fields from an existing entry when editing',
        (tester) async {
      final existing = FuelLogEntry()
        ..supabaseId = 'fuel_1'
        ..boatSupabaseId = '00000000-0000-0000-0000-000000000000'
        ..type = 'Water'
        ..date = DateTime(2026, 1, 1)
        ..liters = 20
        ..pricePerLiter = 0
        ..notes = 'Topped up at the marina';

      FuelLogEntry? saved;
      await _pump(tester, existing: existing, onSave: (e) => saved = e);

      expect(find.text('Topped up at the marina'), findsOneWidget);

      await tester.tap(find.text('Save'));
      await tester.pump();

      // Editing keeps the same identity rather than minting a new entry.
      expect(saved!.supabaseId, 'fuel_1');
      expect(saved!.type, 'Water');
      expect(saved!.liters, 20);
    });
  });
}
