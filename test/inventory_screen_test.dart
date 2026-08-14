import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sisu_mate/models/models.dart';
import 'package:sisu_mate/ui/inventory/inventory_screen.dart';

Future<void> _pump(
  WidgetTester tester, {
  InventoryItem? existing,
  required void Function(InventoryItem) onSave,
  List<ChecklistItem> maintenanceItems = const [],
  List<ChecklistGroup> maintenanceGroups = const [],
}) {
  return tester.pumpWidget(MaterialApp(
    home: Scaffold(
      body: AddEditInventoryItemDialog(
        existing: existing,
        onSave: onSave,
        maintenanceItems: maintenanceItems,
        maintenanceGroups: maintenanceGroups,
      ),
    ),
  ));
}

Future<void> _reveal(WidgetTester tester, Finder finder) =>
    tester.ensureVisible(finder);

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

    testWidgets('#318: barcode field pre-fills and saves manual entry',
        (tester) async {
      final existing = InventoryItem()
        ..supabaseId = 'inv_1'
        ..name = 'Spare impeller'
        ..barcode = '012345678905';

      InventoryItem? saved;
      await _pump(tester, existing: existing, onSave: (i) => saved = i);

      expect(
        tester
            .widget<TextFormField>(
                find.widgetWithText(TextFormField, 'Barcode'))
            .controller!
            .text,
        '012345678905',
      );

      await tester.enterText(
          find.widgetWithText(TextFormField, 'Barcode'), '098765432109');
      await tester.tap(find.text('Save'));
      await tester.pump();

      expect(saved!.barcode, '098765432109');
    });

    testWidgets('#318: empty barcode saves as null, not an empty string',
        (tester) async {
      InventoryItem? saved;
      await _pump(tester, onSave: (i) => saved = i);

      await tester.enterText(
          find.widgetWithText(TextFormField, 'Name'), 'New item');
      await tester.tap(find.text('Save'));
      await tester.pump();

      expect(saved!.barcode, isNull);
    });

    testWidgets('#319: used-by picker is hidden with no maintenance tasks',
        (tester) async {
      await _pump(tester, onSave: (_) {});
      expect(find.text('Used by'), findsNothing);
    });

    testWidgets('#319: linking a spare to a maintenance task saves its supabaseId',
        (tester) async {
      final group = ChecklistGroup()
        ..supabaseId = 'grp_eng'
        ..title = 'Engine Room';
      final task = ChecklistItem()
        ..supabaseId = 'maint_impeller'
        ..groupSupabaseId = 'grp_eng'
        ..title = 'Replace impeller';

      InventoryItem? saved;
      await _pump(
        tester,
        onSave: (i) => saved = i,
        maintenanceItems: [task],
        maintenanceGroups: [group],
      );

      await tester.enterText(
          find.widgetWithText(TextFormField, 'Name'), 'Spare impeller');

      final picker =
          find.widgetWithText(DropdownButtonFormField<String?>, 'Used by');
      await _reveal(tester, picker);
      await tester.tap(picker);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Engine Room — Replace impeller').last);
      await tester.pumpAndSettle();

      final saveButton = find.text('Save');
      await _reveal(tester, saveButton);
      await tester.tap(saveButton);
      await tester.pump();

      expect(saved!.linkedMaintenanceItemSupabaseId, 'maint_impeller');
    });

    testWidgets(
        '#319: editing a linked spare pre-selects the task; None clears it',
        (tester) async {
      final task = ChecklistItem()
        ..supabaseId = 'maint_impeller'
        ..groupSupabaseId = 'grp_eng'
        ..title = 'Replace impeller';
      final existing = InventoryItem()
        ..supabaseId = 'inv_1'
        ..name = 'Spare impeller'
        ..linkedMaintenanceItemSupabaseId = 'maint_impeller';

      InventoryItem? saved;
      await _pump(
        tester,
        existing: existing,
        onSave: (i) => saved = i,
        maintenanceItems: [task],
      );

      final picker =
          find.widgetWithText(DropdownButtonFormField<String?>, 'Used by');
      await _reveal(tester, picker);
      await tester.tap(picker);
      await tester.pumpAndSettle();
      await tester.tap(find.text('None').last);
      await tester.pumpAndSettle();

      final saveButton = find.text('Save');
      await _reveal(tester, saveButton);
      await tester.tap(saveButton);
      await tester.pump();

      expect(saved!.linkedMaintenanceItemSupabaseId, isNull);
    });
  });
}
