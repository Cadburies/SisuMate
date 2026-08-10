import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sisu_mate/models/models.dart';
import 'package:sisu_mate/ui/documents/documents_screen.dart';

Future<void> _pump(
  WidgetTester tester, {
  Document? existing,
  required void Function(Document) onSave,
  List<CrewMember> crewMembers = const [],
}) {
  return tester.pumpWidget(MaterialApp(
    home: Scaffold(
      body: AddEditDocumentDialog(
        existing: existing,
        onSave: onSave,
        crewMembers: crewMembers,
      ),
    ),
  ));
}

Future<void> _reveal(WidgetTester tester, Finder finder) =>
    tester.ensureVisible(finder);

void main() {
  group('AddEditDocumentDialog (F15)', () {
    testWidgets('saves a new document with title, type, and expiry',
        (tester) async {
      Document? saved;
      await _pump(tester, onSave: (d) => saved = d);

      await tester.enterText(
          find.widgetWithText(TextFormField, 'Title'), 'Boat Registration');
      await tester.tap(find.text('Save'));
      await tester.pump();

      expect(saved, isNotNull);
      expect(saved!.title, 'Boat Registration');
      expect(saved!.type, 'Registration'); // default: first in the list
      expect(saved!.expiry, isNull);
    });

    testWidgets('does not call onSave when the title is empty', (tester) async {
      var saveCalled = false;
      await _pump(tester, onSave: (_) => saveCalled = true);

      await tester.tap(find.text('Save'));
      await tester.pump();

      expect(saveCalled, isFalse);
    });

    testWidgets('pre-fills fields from an existing document when editing',
        (tester) async {
      final existing = Document()
        ..supabaseId = 'doc_1'
        ..boatSupabaseId = '00000000-0000-0000-0000-000000000000'
        ..title = 'Insurance Policy'
        ..type = 'Insurance'
        ..notes = 'Renews every June';

      Document? saved;
      await _pump(tester, existing: existing, onSave: (d) => saved = d);

      expect(find.text('Insurance Policy'), findsOneWidget);
      expect(find.text('Renews every June'), findsOneWidget);

      await tester.tap(find.text('Save'));
      await tester.pump();

      // Editing keeps the same identity rather than minting a new document.
      expect(saved!.supabaseId, 'doc_1');
      expect(saved!.title, 'Insurance Policy');
    });

    testWidgets('#325: crew picker is hidden with no crew members on the boat',
        (tester) async {
      await _pump(tester, onSave: (_) {});
      expect(find.text('Belongs to'), findsNothing);
    });

    testWidgets('#325: linking a document to a crew member saves its supabaseId',
        (tester) async {
      final ada = CrewMember()
        ..supabaseId = 'crew_ada'
        ..name = 'Ada';
      final bo = CrewMember()
        ..supabaseId = 'crew_bo'
        ..name = 'Bo';

      Document? saved;
      await _pump(tester,
          onSave: (d) => saved = d, crewMembers: [ada, bo]);

      await tester.enterText(
          find.widgetWithText(TextFormField, 'Title'), "Ada's Passport");

      final picker = find.widgetWithText(DropdownButtonFormField<String?>, 'Belongs to');
      await _reveal(tester, picker);
      await tester.tap(picker);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Ada').last);
      await tester.pumpAndSettle();

      final saveButton = find.text('Save');
      await _reveal(tester, saveButton);
      await tester.tap(saveButton);
      await tester.pump();

      expect(saved!.crewMemberSupabaseId, 'crew_ada');
    });

    testWidgets('#325: editing an already-linked document pre-selects that '
        'crew member, "None" clears the link', (tester) async {
      final ada = CrewMember()
        ..supabaseId = 'crew_ada'
        ..name = 'Ada';
      final existing = Document()
        ..supabaseId = 'doc_1'
        ..title = "Ada's Passport"
        ..type = 'Passport'
        ..crewMemberSupabaseId = 'crew_ada';

      Document? saved;
      await _pump(tester,
          existing: existing, onSave: (d) => saved = d, crewMembers: [ada]);

      final picker = find.widgetWithText(DropdownButtonFormField<String?>, 'Belongs to');
      await _reveal(tester, picker);
      await tester.tap(picker);
      await tester.pumpAndSettle();
      await tester.tap(find.text('None').last);
      await tester.pumpAndSettle();

      final saveButton = find.text('Save');
      await _reveal(tester, saveButton);
      await tester.tap(saveButton);
      await tester.pump();

      expect(saved!.crewMemberSupabaseId, isNull);
    });
  });
}
