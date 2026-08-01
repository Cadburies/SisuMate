import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sisu_mate/core/di.dart';
import 'package:sisu_mate/models/models.dart';
import 'package:sisu_mate/ui/chef/meal_planner_screen.dart';

Future<void> _pump(
  WidgetTester tester, {
  MealPlan? existing,
  required Future<void> Function(MealPlan) onSave,
}) {
  return tester.pumpWidget(
    ProviderScope(
      overrides: [
        guestProfilesProvider.overrideWith(
          (ref) => Stream.value(const <GuestProfile>[]),
        ),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: AddEditMealPlanDialog(existing: existing, onSave: onSave),
        ),
      ),
    ),
  );
}

void main() {
  group('AddEditMealPlanDialog (TEST5)', () {
    testWidgets('creates a plan with default 7 days and 4 guests',
        (tester) async {
      MealPlan? saved;
      await _pump(tester, onSave: (p) async => saved = p);
      await tester.pumpAndSettle();

      expect(find.text('New Meal Plan'), findsOneWidget);

      await tester.enterText(
          find.widgetWithText(TextField, 'Plan name'), 'Passage week');
      await tester.tap(find.text('Create'));
      await tester.pumpAndSettle();

      expect(saved, isNotNull);
      expect(saved!.name, 'Passage week');
      expect(saved!.numberOfDays, 7);
      expect(saved!.guestCount, 4);
    });

    testWidgets('does not save when plan name is cleared', (tester) async {
      var called = false;
      await _pump(tester, onSave: (_) async => called = true);
      await tester.pumpAndSettle();

      await tester.enterText(find.widgetWithText(TextField, 'Plan name'), '');
      await tester.pump();

      final create = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, 'Create'),
      );
      expect(create.onPressed, isNull);

      await tester.tap(find.text('Create'));
      await tester.pump();
      expect(called, isFalse);
    });

    testWidgets('pre-fills and can bump trip length when editing',
        (tester) async {
      final existing = MealPlan()
        ..id = 9
        ..name = 'Long weekend'
        ..numberOfDays = 3
        ..guestCount = 2
        ..startDate = DateTime(2026, 8, 1)
        ..slots = [
          MealPlanSlot()
            ..dayOffset = 0
            ..mealType = 'dinner'
            ..recipeSupabaseId = 'r1',
          // Already past numberOfDays — pruned on save even if length increases.
          MealPlanSlot()
            ..dayOffset = 5
            ..mealType = 'lunch'
            ..recipeSupabaseId = 'r2',
        ];

      MealPlan? saved;
      await _pump(
        tester,
        existing: existing,
        onSave: (p) async => saved = p,
      );
      await tester.pumpAndSettle();

      expect(find.text('Edit Meal Plan'), findsOneWidget);
      expect(find.text('Long weekend'), findsOneWidget);
      expect(find.text('3'), findsOneWidget);

      // Increase trip length once (3 → 4).
      await tester.tap(find.byIcon(Icons.add_circle_outline).first);
      await tester.pump();
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(saved!.id, 9);
      expect(saved!.name, 'Long weekend');
      expect(saved!.numberOfDays, 4);
      // dayOffset 5 still >= 4 → pruned; only day 0 kept.
      expect(saved!.slots.map((s) => s.dayOffset), [0]);
    });

    testWidgets('shortening trip drops slots past the new day count',
        (tester) async {
      final existing = MealPlan()
        ..name = 'Shorten me'
        ..numberOfDays = 5
        ..guestCount = 2
        ..startDate = DateTime(2026, 8, 1)
        ..slots = [
          MealPlanSlot()..dayOffset = 0..mealType = 'dinner'..recipeSupabaseId = 'a',
          MealPlanSlot()..dayOffset = 4..mealType = 'lunch'..recipeSupabaseId = 'b',
        ];

      MealPlan? saved;
      await _pump(
        tester,
        existing: existing,
        onSave: (p) async => saved = p,
      );
      await tester.pumpAndSettle();

      // Decrease length twice: 5 → 4 → 3 (drops dayOffset 4).
      await tester.tap(find.byIcon(Icons.remove_circle_outline).first);
      await tester.pump();
      await tester.tap(find.byIcon(Icons.remove_circle_outline).first);
      await tester.pump();
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(saved!.numberOfDays, 3);
      expect(saved!.slots.map((s) => s.dayOffset), [0]);
    });
  });
}
