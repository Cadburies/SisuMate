import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sisu_mate/models/models.dart';
import 'package:sisu_mate/ui/inventory/inventory_screen.dart';

Future<void> _pump(
  WidgetTester tester, {
  InventoryItem? existing,
  required void Function(InventoryItem) onSave,
}) {
  return tester.pumpWidget(MaterialApp(
    home: Scaffold(
      body: AddEditInventoryItemDialog(existing: existing, onSave: onSave),
    ),
  ));
}

void main() {
  group('AddEditInventoryItemDialog', () {
    testWidgets('saves a new item with a default quantity of 1', (tester) async {
      InventoryItem? saved;
      await _pump(tester, onSave: (i) => saved = i);

      await tester.enterText(
          find.widgetWithText(TextFormField, 'Name'), 'Spare fuel filter');
      await tester.tap(find.text('Save'));
      await tester.pump();

      expect(saved, isNotNull);
      expect(saved!.name, 'Spare fuel filter');
      expect(saved!.quantity, 1);
      expect(saved!.location, isNull);
    });

    testWidgets('does not call onSave when the name is empty', (tester) async {
      var saveCalled = false;
      await _pump(tester, onSave: (_) => saveCalled = true);

      await tester.tap(find.text('Save'));
      await tester.pump();

      expect(saveCalled, isFalse);
    });

    testWidgets('pre-fills fields from an existing item when editing',
        (tester) async {
      final existing = InventoryItem()
        ..supabaseId = 'inv_1'
        ..boatSupabaseId = '00000000-0000-0000-0000-000000000000'
        ..name = 'Life jacket'
        ..location = 'Aft locker'
        ..quantity = 4
        ..unit = 'pcs';

      InventoryItem? saved;
      await _pump(tester, existing: existing, onSave: (i) => saved = i);

      expect(find.text('Life jacket'), findsOneWidget);
      expect(find.text('Aft locker'), findsOneWidget);
      expect(find.text('4'), findsOneWidget);

      await tester.tap(find.text('Save'));
      await tester.pump();

      // Editing keeps the same identity rather than minting a new item.
      expect(saved!.supabaseId, 'inv_1');
      expect(saved!.name, 'Life jacket');
      expect(saved!.quantity, 4);
    });
  });
}
