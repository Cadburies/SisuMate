import 'package:drift/native.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sisu_mate/core/di.dart';
import 'package:sisu_mate/data/drift/app_database.dart';
import 'package:sisu_mate/providers/home_tile_order_provider.dart';
import 'package:sisu_mate/providers/passage_readiness_provider.dart';
import 'package:sisu_mate/services/revenuecat_service.dart';
import 'package:sisu_mate/services/suggestion_engine.dart';
import 'package:sisu_mate/ui/home/components/home_module_tile.dart';
import 'package:sisu_mate/ui/home/home_modules.dart';
import 'package:sisu_mate/ui/home/home_screen.dart';

import 'test_helpers/platform_mocks.dart';

/// #351 — long-press jiggle edit + persisted home-tile order.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;

  setUp(() {
    mockConnectivityChannel();
    mockPathProviderChannel();
    SharedPreferences.setMockInitialValues({});
    db = AppDatabase.forTesting(NativeDatabase.memory());
    RevenueCatService.debugProOverrideForTests = false;
  });

  tearDown(() async {
    RevenueCatService.debugProOverrideForTests = null;
    await db.close();
  });

  List<String> tileIds(WidgetTester tester) => tester
      .widgetList<HomeModuleTile>(find.byType(HomeModuleTile))
      .map((t) => t.module.id)
      .toList();

  Future<ProviderContainer> pumpHome(
    WidgetTester tester, {
    Map<String, Object> prefs = const {},
  }) async {
    SharedPreferences.setMockInitialValues(prefs);
    final container = ProviderContainer(overrides: [
      appDatabaseProvider.overrideWithValue(db),
      isProProvider.overrideWith((ref) => Stream.value(false)),
      boatSuggestionsProvider.overrideWith((ref) => const <BoatSuggestion>[]),
      passageReadinessProvider.overrideWith(
        (ref) => const PassageReadiness(
          status: ReadinessStatus.ready,
          blockers: [],
        ),
      ),
    ]);
    addTearDown(container.dispose);

    await tester.binding.setSurfaceSize(const Size(400, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: HomeScreen()),
      ),
    );
    await container.read(homeTileOrderProvider.notifier).loadFromPrefs();
    for (var i = 0; i < 8; i++) {
      await tester.pump(const Duration(milliseconds: 16));
    }
    await tester.pump(const Duration(milliseconds: 500));
    return container;
  }

  testWidgets('default grid is Shopping first, Games last', (tester) async {
    await pumpHome(tester);
    final ids = tileIds(tester);
    expect(ids.first, 'shopping');
    expect(ids.last, 'games');
    expect(find.text('Weather'), findsOneWidget);
    expect(find.byKey(const ValueKey('home_tile_edit_done')), findsNothing);
  });

  testWidgets('saved prefs put Weather in the top-left', (tester) async {
    final saved = [
      'weather',
      ...HomeModules.defaultIds.where((id) => id != 'weather'),
    ];
    await pumpHome(tester, prefs: {kHomeTileOrderPrefsKey: saved});
    expect(tileIds(tester).first, 'weather');
  });

  testWidgets('long-press enters edit mode; Done exits', (tester) async {
    final container = await pumpHome(tester);

    await tester.longPress(find.byKey(const ValueKey('home_tile_weather')));
    await tester.pump();

    expect(container.read(homeTileEditModeProvider), isTrue);
    expect(find.byKey(const ValueKey('home_tile_edit_done')), findsOneWidget);
    expect(find.byType(HomeTileJiggle), findsWidgets);

    // Tap a tile in edit mode — onTap is disabled, so no GoRouter throw.
    await tester.tap(find.byKey(const ValueKey('home_tile_weather')));
    await tester.pump();
    expect(find.byType(HomeScreen), findsOneWidget);
    expect(container.read(homeTileEditModeProvider), isTrue);

    await tester.tap(find.byKey(const ValueKey('home_tile_edit_done')));
    await tester.pump();
    expect(container.read(homeTileEditModeProvider), isFalse);
    expect(find.byKey(const ValueKey('home_tile_edit_done')), findsNothing);
  });

  testWidgets('moveIdTo persists Weather to the front', (tester) async {
    final container = await pumpHome(tester);
    await container
        .read(homeTileOrderProvider.notifier)
        .moveIdTo('weather', 0);
    await tester.pump();

    expect(tileIds(tester).first, 'weather');
    expect(container.read(homeTileOrderProvider).first, 'weather');

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getStringList(kHomeTileOrderPrefsKey)!.first, 'weather');
  });

  testWidgets('drag Weather onto Shopping in edit mode', (tester) async {
    await pumpHome(tester);

    final weather = tester.getCenter(
      find.byKey(const ValueKey('home_tile_weather')),
    );
    final shopping = tester.getCenter(
      find.byKey(const ValueKey('home_tile_shopping')),
    );

    final gesture = await tester.startGesture(weather);
    await tester.pump(kLongPressTimeout + const Duration(milliseconds: 50));
    await gesture.moveTo(shopping);
    await tester.pump();
    await gesture.up();
    for (var i = 0; i < 8; i++) {
      await tester.pump(const Duration(milliseconds: 16));
    }

    expect(tileIds(tester).first, 'weather');
    expect(find.byKey(const ValueKey('home_tile_edit_done')), findsOneWidget);
  });
}
