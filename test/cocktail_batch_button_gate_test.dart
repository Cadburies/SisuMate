import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sisu_mate/core/di.dart';
import 'package:sisu_mate/data/drift/app_database.dart';
import 'package:sisu_mate/models/models.dart';
import 'package:sisu_mate/services/revenuecat_service.dart';
import 'package:sisu_mate/ui/cocktails/cocktails_screen.dart';

import 'test_helpers/platform_mocks.dart';

/// Regression for #140: "Build a Round" pushed a syrup/house-mix Recipe into
/// [CocktailBatchScreen], whose dropdown only lists cocktail-type recipes —
/// zero matching items crashes Flutter's DropdownButton assertion. Fix gates
/// the button on `recipeType == 'cocktail'` (cocktails_screen.dart ~1177).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late AppDatabase db;

  setUp(() {
    mockConnectivityChannel();
    mockPathProviderChannel();
    mockSharedPreferencesChannel();
    db = AppDatabase.forTesting(NativeDatabase.memory());
    RevenueCatService.debugProOverrideForTests = false;
  });

  tearDown(() async {
    RevenueCatService.debugProOverrideForTests = null;
    await db.close();
  });

  Recipe buildRecipe({required String supabaseId, required String recipeType}) {
    return Recipe()
      ..supabaseId = supabaseId
      ..name = 'Test Recipe'
      ..recipeType = recipeType;
  }

  Future<void> pumpDetail(WidgetTester tester, Recipe recipe) async {
    final container = ProviderContainer(overrides: [
      appDatabaseProvider.overrideWithValue(db),
      isProProvider.overrideWith((ref) => Stream.value(true)),
    ]);
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: CocktailRecipeDetailScreen(recipe: recipe),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
  }

  testWidgets('non-cocktail recipe (syrup) hides "Build a Round"', (tester) async {
    await pumpDetail(
      tester,
      buildRecipe(supabaseId: 'syrup_1', recipeType: 'syrup'),
    );

    expect(find.text('Build a Round'), findsNothing);
  });

  testWidgets('menu recipe hides "Build a Round"', (tester) async {
    await pumpDetail(
      tester,
      buildRecipe(supabaseId: 'menu_1', recipeType: 'menu'),
    );

    expect(find.text('Build a Round'), findsNothing);
  });

  testWidgets('cocktail recipe still shows "Build a Round"', (tester) async {
    await pumpDetail(
      tester,
      buildRecipe(supabaseId: 'cocktail_1', recipeType: 'cocktail'),
    );

    expect(find.text('Build a Round'), findsOneWidget);
  });
}
