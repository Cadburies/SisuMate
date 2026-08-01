import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sisu_mate/models/models.dart';
import 'package:sisu_mate/ui/chef/guest_profiles_screen.dart';

Future<void> _pump(
  WidgetTester tester, {
  GuestProfile? existing,
  required Future<void> Function(GuestProfile) onSave,
}) {
  return tester.pumpWidget(MaterialApp(
    home: Scaffold(
      body: AddEditGuestProfileDialog(existing: existing, onSave: onSave),
    ),
  ));
}

void main() {
  group('AddEditGuestProfileDialog (TEST5)', () {
    testWidgets('Add is disabled until a name is entered', (tester) async {
      var called = false;
      await _pump(tester, onSave: (_) async => called = true);

      final add = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, 'Add'),
      );
      expect(add.onPressed, isNull);

      await tester.tap(find.text('Add'));
      await tester.pump();
      expect(called, isFalse);
    });

    testWidgets('saves name plus selected allergen and dietary chips',
        (tester) async {
      GuestProfile? saved;
      await _pump(tester, onSave: (p) async => saved = p);

      await tester.enterText(
          find.widgetWithText(TextField, 'Name'), 'Alice');
      await tester.pump();

      await tester.tap(find.widgetWithText(FilterChip, 'dairy'));
      await tester.pump();
      await tester.tap(find.widgetWithText(FilterChip, 'vegan'));
      await tester.pump();

      await tester.tap(find.text('Add'));
      await tester.pumpAndSettle();

      expect(saved, isNotNull);
      expect(saved!.name, 'Alice');
      expect(saved!.allergenRestrictions, contains('dairy'));
      expect(saved!.dietaryRequirements, contains('vegan'));
    });

    testWidgets('pre-fills existing profile and Save keeps identity',
        (tester) async {
      final existing = GuestProfile()
        ..id = 42
        ..name = 'Bob'
        ..allergenRestrictions = ['nuts']
        ..dietaryRequirements = ['halal'];

      GuestProfile? saved;
      await _pump(
        tester,
        existing: existing,
        onSave: (p) async => saved = p,
      );

      expect(find.text('Edit Profile'), findsOneWidget);
      expect(find.text('Bob'), findsOneWidget);

      await tester.enterText(
          find.widgetWithText(TextField, 'Name'), 'Robert');
      await tester.pump();
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(saved!.id, 42);
      expect(saved!.name, 'Robert');
      expect(saved!.allergenRestrictions, ['nuts']);
      expect(saved!.dietaryRequirements, ['halal']);
    });
  });
}
