import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sisu_mate/models/models.dart';
import 'package:sisu_mate/ui/logbook/logbook_screen.dart';

Future<void> _pump(
  WidgetTester tester, {
  CaptainLogEntry? existing,
  required Future<void> Function(CaptainLogEntry) onSave,
}) {
  return tester.pumpWidget(MaterialApp(
    home: Scaffold(
      body: AddEditCaptainLogDialog(existing: existing, onSave: onSave),
    ),
  ));
}

void main() {
  group('AddEditCaptainLogDialog', () {
    testWidgets('saves a new log entry with notes and weather', (tester) async {
      CaptainLogEntry? saved;
      await _pump(tester, onSave: (e) async => saved = e);

      await tester.enterText(
          find.widgetWithText(TextFormField, 'Notes'), 'Left anchorage at 0800');
      await tester.enterText(
          find.widgetWithText(TextFormField, 'Weather'), 'Clear, light breeze');
      await tester.enterText(
          find.widgetWithText(TextFormField, 'Wind (kt)'), '12');
      await tester.tap(find.text('Save'));
      await tester.pump();

      expect(saved, isNotNull);
      expect(saved!.notes, 'Left anchorage at 0800');
      expect(saved!.weather, 'Clear, light breeze');
      expect(saved!.windSpeedKt, 12);
      expect(saved!.supabaseId, startsWith('log_'));
    });

    testWidgets('rejects invalid wind speed number', (tester) async {
      var saveCalled = false;
      await _pump(tester, onSave: (_) async => saveCalled = true);

      await tester.enterText(
          find.widgetWithText(TextFormField, 'Wind (kt)'), 'not-a-number');
      await tester.tap(find.text('Save'));
      await tester.pump();

      expect(saveCalled, isFalse);
      expect(find.text('Invalid number'), findsOneWidget);
    });

    testWidgets('pre-fills fields when editing an existing entry',
        (tester) async {
      final existing = CaptainLogEntry()
        ..supabaseId = 'log_existing'
        ..boatSupabaseId = '00000000-0000-0000-0000-000000000000'
        ..notes = 'Night watch'
        ..weather = 'Overcast'
        ..windSpeedKt = 8
        ..crewOnBoard = ['Alex', 'Sam'];

      CaptainLogEntry? saved;
      await _pump(
        tester,
        existing: existing,
        onSave: (e) async => saved = e,
      );

      expect(find.text('Night watch'), findsOneWidget);
      expect(find.text('Overcast'), findsOneWidget);
      expect(find.text('Alex, Sam'), findsOneWidget);

      await tester.tap(find.text('Save'));
      await tester.pump();

      expect(saved!.supabaseId, 'log_existing');
      expect(saved!.notes, 'Night watch');
      expect(saved!.crewOnBoard, ['Alex', 'Sam']);
    });
  });
}
