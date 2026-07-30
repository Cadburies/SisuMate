import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sisu_mate/models/models.dart';
import 'package:sisu_mate/ui/crew/crew_screen.dart';

Future<void> _pump(
  WidgetTester tester, {
  CrewMember? existing,
  required void Function(CrewMember) onSave,
}) {
  return tester.pumpWidget(MaterialApp(
    home: Scaffold(
      body: AddEditCrewMemberDialog(existing: existing, onSave: onSave),
    ),
  ));
}

void main() {
  group('AddEditCrewMemberDialog', () {
    testWidgets('saves a new crew member with the default role', (tester) async {
      CrewMember? saved;
      await _pump(tester, onSave: (m) => saved = m);

      await tester.enterText(
          find.widgetWithText(TextFormField, 'Name'), 'Alex Sailor');
      await tester.tap(find.text('Save'));
      await tester.pump();

      expect(saved, isNotNull);
      expect(saved!.name, 'Alex Sailor');
      expect(saved!.role, 'Crew');
      expect(saved!.phone, isNull);
    });

    testWidgets('does not call onSave when the name is empty', (tester) async {
      var saveCalled = false;
      await _pump(tester, onSave: (_) => saveCalled = true);

      await tester.tap(find.text('Save'));
      await tester.pump();

      expect(saveCalled, isFalse);
    });

    testWidgets('pre-fills fields from an existing crew member when editing',
        (tester) async {
      final existing = CrewMember()
        ..supabaseId = 'crew_1'
        ..boatSupabaseId = '00000000-0000-0000-0000-000000000000'
        ..name = 'Jamie Mate'
        ..role = 'Captain'
        ..phone = '555-1234';

      CrewMember? saved;
      await _pump(tester, existing: existing, onSave: (m) => saved = m);

      expect(find.text('Jamie Mate'), findsOneWidget);
      expect(find.text('555-1234'), findsOneWidget);

      await tester.tap(find.text('Save'));
      await tester.pump();

      // Editing keeps the same identity rather than minting a new member.
      expect(saved!.supabaseId, 'crew_1');
      expect(saved!.name, 'Jamie Mate');
      expect(saved!.role, 'Captain');
    });
  });
}
