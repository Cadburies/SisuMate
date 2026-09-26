import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';

import '_reach.dart';

/// Feature Map scripts for `.ai_context/feature_map/home/chef*`.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Meal plans are named after their start week, so tests compute the title.
  String planTitle() => 'Week of ${DateFormat('MMM d').format(DateTime.now())}';

  testWidgets('home/chef', (tester) async {
    await reach(tester, 'home/chef');
    expect(find.text('Amarula Malva'), findsOneWidget);
  });

  testWidgets('home/chef/recipe', (tester) async {
    await reach(tester, 'home/chef/recipe');
    expect(find.text('Ingredients'), findsOneWidget);
    expect(find.text('Suggested Pairing'), findsOneWidget);
  });

  testWidgets('home/chef/recipe/cook', (tester) async {
    await reach(tester, 'home/chef/recipe/cook');
    expect(find.text('Step 1 of 2'), findsOneWidget);
  });

  testWidgets('home/chef/recipe/add_missing', (tester) async {
    await reach(tester, 'home/chef/recipe/add_missing');
    await runStep(tester, 'wait:2 pack lines added to shopping');
  });

  testWidgets('home/chef/recipe/leftovers', (tester) async {
    await reach(tester, 'home/chef/recipe/leftovers');
    expect(find.text('Leftover Ideas'), findsOneWidget);
  });

  testWidgets('home/chef/recipe/favourite', (tester) async {
    await reach(tester, 'home/chef/recipe/favourite');
    expect(find.byTooltip('Favourite'), findsOneWidget);
  });

  testWidgets('home/chef/add_recipe', (tester) async {
    await reach(tester, 'home/chef/add_recipe');
    expect(find.text('Add manually'), findsOneWidget);
    expect(find.text('Import from URL'), findsOneWidget);
  });

  testWidgets('home/chef/add_recipe [free]', (tester) async {
    await reach(tester, 'home/chef/add_recipe', tier: 'free');
    expect(find.text('Add manually'), findsNothing);
    expect(find.byType(AlertDialog), findsOneWidget);
  });

  testWidgets('home/chef/add_recipe/manual', (tester) async {
    await reach(tester, 'home/chef/add_recipe/manual');
    expect(find.text('Add Recipe'), findsWidgets);
  });

  testWidgets('home/chef/pantry', (tester) async {
    await reach(tester, 'home/chef/pantry');
    expect(find.text('Aged Balsamic Vinegar'), findsOneWidget);
  });

  testWidgets('home/chef/pantry/add_ingredient', (tester) async {
    await reach(tester, 'home/chef/pantry/add_ingredient');
    expect(find.text('Add Pantry Item'), findsOneWidget);
  });

  testWidgets('home/chef/corner', (tester) async {
    await reach(tester, 'home/chef/corner');
    expect(find.text('Suggest a Dish'), findsOneWidget);
  });

  testWidgets('home/chef/corner/guest_profiles', (tester) async {
    await reach(tester, 'home/chef/corner/guest_profiles');
    expect(find.byTooltip('Add guest profile'), findsOneWidget);
  });

  testWidgets('home/chef/corner/add_guest_profile', (tester) async {
    await reach(tester, 'home/chef/corner/add_guest_profile');
    expect(find.text('New Guest Profile'), findsOneWidget);
  });

  testWidgets('home/chef/meal_planner', (tester) async {
    await reach(tester, 'home/chef/meal_planner');
    expect(find.text('No meal plans yet'), findsOneWidget);
  });

  testWidgets('home/chef/meal_planner/new_plan', (tester) async {
    await reach(tester, 'home/chef/meal_planner/new_plan');
    expect(find.text('New Meal Plan'), findsOneWidget);
  });

  testWidgets('home/chef/meal_planner/plan', (tester) async {
    await reach(tester, 'home/chef/meal_planner/plan');
    await runStep(tester, 'text:${planTitle()}');
    expect(find.text('Dinner'), findsWidgets);
    expect(find.byTooltip('Provision list'), findsOneWidget);
  });

  testWidgets('home/chef/meal_planner/provision', (tester) async {
    await reach(tester, 'home/chef/meal_planner/provision');
    await runStep(tester, 'text:${planTitle()}');
    await runStep(tester, 'tip:Provision list');
    expect(find.text('Consolidated Provisions'), findsOneWidget);
    expect(find.text('Shopping shortfall'), findsOneWidget);
  });

  testWidgets('home/chef/collections', (tester) async {
    await reach(tester, 'home/chef/collections');
    expect(find.text('No collections yet'), findsOneWidget);
  });

  testWidgets('home/chef/collections/new_collection', (tester) async {
    await reach(tester, 'home/chef/collections/new_collection');
    expect(find.text('New Collection'), findsOneWidget);
  });
}
