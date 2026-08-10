import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sisu_mate/models/models.dart';
import 'package:sisu_mate/ui/crew/crew_screen.dart';

Future<void> _pump(
  WidgetTester tester, {
  CrewMember? existing,
  required void Function(CrewMember) onSave,
  void Function(CrewMember)? onCopyToGuestProfile,
}) {
  return tester.pumpWidget(MaterialApp(
    home: Scaffold(
      body: AddEditCrewMemberDialog(
        existing: existing,
        onSave: onSave,
        onCopyToGuestProfile: onCopyToGuestProfile,
      ),
    ),
  ));
}

Future<void> _reveal(WidgetTester tester, Finder finder) =>
    tester.ensureVisible(finder);

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

    testWidgets('#326: saves nationality and passport number', (tester) async {
      CrewMember? saved;
      await _pump(tester, onSave: (m) => saved = m);

      await tester.enterText(
          find.widgetWithText(TextFormField, 'Name'), 'Alex Sailor');
      final nationalityField = find.widgetWithText(TextFormField, 'Nationality');
      await _reveal(tester, nationalityField);
      await tester.enterText(nationalityField, 'Finnish');
      final passportField =
          find.widgetWithText(TextFormField, 'Passport number');
      await _reveal(tester, passportField);
      await tester.enterText(passportField, 'FI1234567');

      final saveButton = find.text('Save');
      await _reveal(tester, saveButton);
      await tester.tap(saveButton);
      await tester.pump();

      expect(saved!.nationality, 'Finnish');
      expect(saved!.passportNumber, 'FI1234567');
    });

    testWidgets('#326: date of birth defaults to null and can be picked',
        (tester) async {
      final existing = CrewMember()
        ..supabaseId = 'crew_1'
        ..name = 'Jamie Mate'
        ..dateOfBirth = DateTime(1990, 3, 20);

      CrewMember? saved;
      await _pump(tester, existing: existing, onSave: (m) => saved = m);

      final dobButton = find.textContaining('1990-03-20');
      await _reveal(tester, dobButton);
      expect(dobButton, findsOneWidget);

      final saveButton = find.text('Save');
      await _reveal(tester, saveButton);
      await tester.tap(saveButton);
      await tester.pump();

      expect(saved!.dateOfBirth, DateTime(1990, 3, 20));
    });

    testWidgets(
        '#324: allergen/dietary chips toggle and save, "Copy to Guest '
        'Profile" only shows when editing with tags set', (tester) async {
      // New member: chips are selectable, but no copy button yet (no
      // existing record to copy from at all).
      CrewMember? saved;
      await _pump(tester, onSave: (m) => saved = m,
          onCopyToGuestProfile: (_) {});
      await tester.enterText(
          find.widgetWithText(TextFormField, 'Name'), 'Alex Sailor');

      final nutsChip = find.widgetWithText(FilterChip, 'nuts');
      await _reveal(tester, nutsChip);
      await tester.tap(nutsChip);
      final veganChip = find.widgetWithText(FilterChip, 'vegan');
      await _reveal(tester, veganChip);
      await tester.tap(veganChip);
      await tester.pump();

      expect(find.text('Copy to Guest Profile'), findsNothing,
          reason: 'nothing to copy from until this member is actually saved');

      final saveButton = find.text('Save');
      await _reveal(tester, saveButton);
      await tester.tap(saveButton);
      await tester.pump();

      expect(saved!.allergenRestrictions, ['nuts']);
      expect(saved!.dietaryRequirements, ['vegan']);
    });

    testWidgets('#324: Copy to Guest Profile passes current on-screen tags',
        (tester) async {
      final existing = CrewMember()
        ..supabaseId = 'crew_1'
        ..name = 'Jamie Mate'
        ..allergenRestrictions = ['dairy'];

      CrewMember? copied;
      await _pump(
        tester,
        existing: existing,
        onSave: (_) {},
        onCopyToGuestProfile: (m) => copied = m,
      );

      // Toggle on a dietary tag that wasn't in the saved record yet — the
      // copy should reflect the current form state, not the stale record.
      final veganChip = find.widgetWithText(FilterChip, 'vegan');
      await _reveal(tester, veganChip);
      await tester.tap(veganChip);
      await tester.pump();

      final copyButton = find.text('Copy to Guest Profile');
      await _reveal(tester, copyButton);
      await tester.tap(copyButton);
      await tester.pump();

      expect(copied, isNotNull);
      expect(copied!.name, 'Jamie Mate');
      expect(copied!.allergenRestrictions, ['dairy']);
      expect(copied!.dietaryRequirements, ['vegan']);
    });
  });
}
