import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sisu_mate/ui/components/add_checklist_item_dialog.dart';

Future<ChecklistItemFormResult?> _open(
  WidgetTester tester, {
  String itemNoun = 'item',
}) async {
  ChecklistItemFormResult? result;
  await tester.pumpWidget(MaterialApp(
    home: Builder(
      builder: (context) => Scaffold(
        body: ElevatedButton(
          onPressed: () async {
            result = await showDialog<ChecklistItemFormResult>(
              context: context,
              builder: (_) => AddChecklistItemFormDialog(itemNoun: itemNoun),
            );
          },
          child: const Text('Open'),
        ),
      ),
    ),
  ));
  await tester.tap(find.text('Open'));
  await tester.pumpAndSettle();
  return result;
}

void main() {
  group('AddChecklistItemFormDialog (TEST5)', () {
    testWidgets('Add is disabled with empty title', (tester) async {
      await _open(tester);

      expect(find.text('Add item'), findsOneWidget);
      final add = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, 'Add'),
      );
      expect(add.onPressed, isNull);
    });

    testWidgets('returns title and notes on Add', (tester) async {
      ChecklistItemFormResult? result;
      await tester.pumpWidget(MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: ElevatedButton(
              onPressed: () async {
                result = await showDialog<ChecklistItemFormResult>(
                  context: context,
                  builder: (_) =>
                      const AddChecklistItemFormDialog(itemNoun: 'check'),
                );
              },
              child: const Text('Open'),
            ),
          ),
        ),
      ));
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text('Add check'), findsOneWidget);

      await tester.enterText(
          find.widgetWithText(TextField, 'Title'), 'Inspect bilge pump');
      await tester.enterText(
          find.widgetWithText(TextField, 'Notes (optional)'), 'Listen for air');
      await tester.pump();

      await tester.tap(find.widgetWithText(ElevatedButton, 'Add'));
      await tester.pumpAndSettle();

      expect(result, isNotNull);
      expect(result!.title, 'Inspect bilge pump');
      expect(result!.notes, 'Listen for air');
    });

    testWidgets('Cancel returns null', (tester) async {
      ChecklistItemFormResult? result = const ChecklistItemFormResult(
        title: 'sentinel',
      );
      await tester.pumpWidget(MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: ElevatedButton(
              onPressed: () async {
                result = await showDialog<ChecklistItemFormResult>(
                  context: context,
                  builder: (_) => const AddChecklistItemFormDialog(),
                );
              },
              child: const Text('Open'),
            ),
          ),
        ),
      ));
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(result, isNull);
    });
  });
}
