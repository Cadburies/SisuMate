import 'dart:convert';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sisu_mate/core/di.dart';
import 'package:sisu_mate/data/drift/app_database.dart';
import 'package:sisu_mate/services/auth_service.dart';
import 'package:sisu_mate/services/revenuecat_service.dart';
import 'package:sisu_mate/ui/chef/chef_screen.dart';
import 'package:sisu_mate/ui/cocktails/cocktails_screen.dart';
import 'package:sisu_mate/ui/components/tag_chip.dart';

import 'test_helpers/fake_auth_backend.dart';
import 'test_helpers/platform_mocks.dart';

/// #187: My Bar/My Pantry ingredient tiles now render allergen (red) and
/// flavor-profile (orange) tags as colored [TagChip]s, matching the visual
/// language recipe tiles already use — previously both were one flat,
/// single-color plain-text line.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late AppDatabase db;
  late FakeAuthBackend authBackend;

  setUp(() {
    mockConnectivityChannel();
    mockPathProviderChannel();
    mockSharedPreferencesChannel();
    db = AppDatabase.forTesting(NativeDatabase.memory());
    authBackend = FakeAuthBackend();
    RevenueCatService.debugProOverrideForTests = false;
  });

  tearDown(() async {
    RevenueCatService.debugProOverrideForTests = null;
    authBackend.dispose();
    await db.close();
  });

  Future<ProviderContainer> pumpContainer(WidgetTester tester, Widget home) async {
    final container = ProviderContainer(overrides: [
      appDatabaseProvider.overrideWithValue(db),
      isProProvider.overrideWith((ref) => Stream.value(true)),
      authServiceProvider
          .overrideWith((ref) => AuthService(ref, backend: authBackend)),
    ]);
    addTearDown(container.dispose);
    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: MaterialApp(home: home),
    ));
    await tester.pump();
    await tester.pump();
    return container;
  }

  testWidgets('My Pantry tile shows allergen (red) and flavor (orange) chips',
      (tester) async {
    await db.into(db.pantryIngredients).insert(PantryIngredientsCompanion.insert(
          supabaseId: const Value('pantry_peanut_sauce'),
          name: const Value('Peanut Sauce'),
          inMyPantry: const Value(true),
          allergenTags: Value(jsonEncode(['nuts', 'soy'])),
          flavorProfiles: Value(jsonEncode(['savory', 'nutty'])),
        ));

    await pumpContainer(tester, const ChefScreen());
    await tester.tap(find.text('My Pantry'));
    await tester.pumpAndSettle();

    final nuts = tester.widget<TagChip>(find.byWidgetPredicate(
        (w) => w is TagChip && w.label == 'nuts'));
    expect(nuts.color, Colors.red[700]);

    final savory = tester.widget<TagChip>(find.byWidgetPredicate(
        (w) => w is TagChip && w.label == 'savory'));
    expect(savory.color, Colors.orange[700]);

    // Quantity/price stay plain text, not chips — unaffected by this change.
    expect(find.text('Contains: nuts, soy'), findsNothing,
        reason: 'allergens must render as chips now, not the old flat '
            '"Contains: ..." text line');
  });

  testWidgets('My Bar tile shows flavor (orange) chips', (tester) async {
    await db.into(db.barIngredients).insert(BarIngredientsCompanion.insert(
          supabaseId: const Value('bar_gin'),
          name: const Value('Gin'),
          inMyBar: const Value(true),
          flavorProfiles: Value(jsonEncode(['botanical', 'dry'])),
        ));

    await pumpContainer(tester, const CocktailsScreen());
    await tester.tap(find.text('My Bar'));
    await tester.pumpAndSettle();

    final botanical = tester.widget<TagChip>(find.byWidgetPredicate(
        (w) => w is TagChip && w.label == 'botanical'));
    expect(botanical.color, Colors.orange[700]);
  });
}
