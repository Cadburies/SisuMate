import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sisu_mate/core/di.dart';
import 'package:sisu_mate/data/drift/app_database.dart';
import 'package:sisu_mate/models/models.dart';
import 'package:sisu_mate/services/revenuecat_service.dart';
import 'package:sisu_mate/ui/chef/chef_screen.dart';

import 'test_helpers/platform_mocks.dart';

/// #214: Chef's recipe detail screen shows a "Suggested Pairing" section
/// with the recipe's winePairing/cocktailPairing when present, distinct
/// from the existing "Pairs well with" section (which cross-references
/// this app's own cocktail catalog by keyword, not a curated suggestion).
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

  Future<ProviderContainer> pumpDetail(
    WidgetTester tester,
    Recipe recipe,
  ) async {
    final container = ProviderContainer(overrides: [
      appDatabaseProvider.overrideWithValue(db),
      isProProvider.overrideWith((ref) => Stream.value(true)),
    ]);
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(home: ChefRecipeDetailScreen(recipe: recipe)),
      ),
    );
    await tester.pump();
    await tester.pump();
    return container;
  }

  testWidgets('shows both wine and cocktail pairing text when present',
      (tester) async {
    final recipe = Recipe()
      ..supabaseId = 'menu_test_pairing'
      ..name = 'Test Braai'
      ..recipeType = 'menu'
      ..winePairing = 'Dry rose, or a lightly chilled Zinfandel.'
      ..cocktailPairing = "Dark 'n Stormy - rum and ginger beer.";

    await pumpDetail(tester, recipe);

    expect(find.text('Suggested Pairing'), findsOneWidget);
    expect(find.text('Dry rose, or a lightly chilled Zinfandel.'),
        findsOneWidget);
    expect(find.text("Dark 'n Stormy - rum and ginger beer."), findsOneWidget);
  });

  testWidgets('shows nothing when neither pairing field is set',
      (tester) async {
    final recipe = Recipe()
      ..supabaseId = 'menu_test_no_pairing'
      ..name = 'Untagged Dish'
      ..recipeType = 'menu';

    await pumpDetail(tester, recipe);

    expect(find.text('Suggested Pairing'), findsNothing);
  });
}
