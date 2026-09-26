import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '_reach.dart';

/// Feature Map scripts for `.ai_context/feature_map/home/cocktails*`.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('home/cocktails', (tester) async {
    await reach(tester, 'home/cocktails');
    expect(find.text("Today's cocktail"), findsOneWidget);
    expect(find.text('Mai Tai'), findsOneWidget);
  });

  testWidgets('home/cocktails/cocktail', (tester) async {
    await reach(tester, 'home/cocktails/cocktail');
    expect(find.text('Technique'), findsOneWidget);
    expect(find.text('Ingredients'), findsOneWidget);
  });

  testWidgets('home/cocktails/cocktail/technique', (tester) async {
    await reach(tester, 'home/cocktails/cocktail/technique');
    expect(find.text('Equipment'), findsOneWidget);
    expect(find.text('Steps'), findsOneWidget);
  });

  testWidgets('home/cocktails/cocktail/build_round', (tester) async {
    await reach(tester, 'home/cocktails/cocktail/build_round');
    expect(find.text('Total batch'), findsOneWidget);
  });

  testWidgets('home/cocktails/cocktail/edit', (tester) async {
    await reach(tester, 'home/cocktails/cocktail/edit');
    expect(find.text('Save'), findsOneWidget);
  });

  testWidgets('home/cocktails/cocktail/edit [free]', (tester) async {
    await reach(tester, 'home/cocktails/cocktail', tier: 'free');
    expect(find.byTooltip('Edit cocktail'), findsNothing);
  });

  testWidgets('home/cocktails/add_cocktail', (tester) async {
    await reach(tester, 'home/cocktails/add_cocktail');
    expect(find.text('Add Cocktail'), findsWidgets);
  });

  testWidgets('home/cocktails/add_cocktail [free]', (tester) async {
    await reach(tester, 'home/cocktails/add_cocktail', tier: 'free');
    expect(find.text('Add Cocktail'), findsNothing);
    expect(find.byType(AlertDialog), findsOneWidget);
  });

  testWidgets('home/cocktails/bar', (tester) async {
    await reach(tester, 'home/cocktails/bar');
    expect(find.text('Absinthe'), findsOneWidget);
  });

  testWidgets('home/cocktails/bar/add_ingredient', (tester) async {
    await reach(tester, 'home/cocktails/bar/add_ingredient');
    expect(find.text('Save'), findsOneWidget);
  });

  testWidgets('home/cocktails/mixologist', (tester) async {
    await reach(tester, 'home/cocktails/mixologist');
    expect(find.text('Invent a drink'), findsOneWidget);
  });

  testWidgets('home/cocktails/mixologist/rank', (tester) async {
    await reach(tester, 'home/cocktails/mixologist/rank');
    expect(find.text('Refresh ranking'), findsOneWidget);
    expect(find.textContaining('missing:'), findsWidgets);
  });

  testWidgets('home/cocktails/house', (tester) async {
    await reach(tester, 'home/cocktails/house');
    expect(find.text('Demerara Syrup'), findsOneWidget);
  });

  testWidgets('home/cocktails/house/add_house_recipe', (tester) async {
    await reach(tester, 'home/cocktails/house/add_house_recipe');
    expect(find.text('Add House Recipe'), findsWidgets);
  });
}
