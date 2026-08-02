import 'dart:convert';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sisu_mate/core/di.dart';
import 'package:sisu_mate/data/drift/app_database.dart';
import 'package:sisu_mate/services/revenuecat_service.dart';
import 'package:sisu_mate/services/weather_service.dart';
import 'package:sisu_mate/ui/weather/passage_planner_screen.dart';
import 'package:sisu_mate/ui/weather/passage_weather_briefing_dialog.dart';

import 'test_helpers/platform_mocks.dart';

/// #219: the passage planner's AI briefing reads BAI1's local-cache-only
/// weather (no new network call) and reasons over it via #203's BYOK
/// client. #208 separation from the offline "Add waypoint" control beside
/// it; a missing cache and a missing key both fail clearly, never silently.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late AppDatabase db;

  WeatherBundle sampleBundle() => WeatherBundle(
        lat: 22.89,
        lon: -109.91,
        fetchedAt: DateTime.now(),
        fromCache: true,
        placeName: 'Cabo San Lucas',
        hourly: [
          HourlyWeather(
            time: DateTime.now(),
            windMs: 9.5,
            windDirDeg: 270,
            precipProb: 10,
          ),
        ],
        marine: [
          HourlyMarine(
            time: DateTime.now(),
            waveHeightM: 1.1,
            waveDirDeg: 260,
            wavePeriodS: 7,
          ),
        ],
      );

  setUp(() {
    mockConnectivityChannel();
    // #219 note: unlike the other LLM dialog tests, this screen embeds a
    // live `FlutterMap` (waypoint map) whose tile-caching provider calls
    // `path_provider.getApplicationCacheDirectory()` — a method
    // `mockPathProviderChannel()` doesn't stub, and stubbing it to return
    // null (rather than leaving the channel unmocked) trips
    // `MissingPlatformDirectoryException` inside flutter_map, same as plain
    // `passage_planner_screen_test.dart` which also skips this call.
    mockSharedPreferencesChannel();
    db = AppDatabase.forTesting(NativeDatabase.memory());
    RevenueCatService.debugProOverrideForTests = false;
  });

  tearDown(() async {
    RevenueCatService.debugProOverrideForTests = null;
    await db.close();
  });

  Future<ProviderContainer> pumpScreen(WidgetTester tester,
      {WeatherBundle? cachedWeather,
      String? llmApiKey,
      String? llmApiKeyProvider}) async {
    SharedPreferences.setMockInitialValues(cachedWeather == null
        ? {}
        : {'weather_cache_v2': jsonEncode(cachedWeather.toJson())});

    await db.into(db.boats).insert(BoatsCompanion.insert(
          supabaseId: const Value('boat_1'),
          name: const Value('Sisu'),
          llmApiKey: Value(llmApiKey),
          llmApiKeyProvider: Value(llmApiKeyProvider),
        ));
    await db.into(db.userSettingsTable).insert(
          UserSettingsTableCompanion.insert(
            id: const Value(1),
            activeBoatSupabaseId: const Value('boat_1'),
          ),
        );

    final container = ProviderContainer(overrides: [
      appDatabaseProvider.overrideWithValue(db),
      isProProvider.overrideWith((ref) => Stream.value(true)),
    ]);
    addTearDown(container.dispose);

    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(home: PassagePlannerScreen()),
    ));
    await tester.pump();
    await tester.pump();
    return container;
  }

  testWidgets('the AI badge renders distinct from the add-waypoint action',
      (tester) async {
    await pumpScreen(tester);

    expect(find.byIcon(Icons.auto_awesome), findsOneWidget,
        reason: '#208: AI entry point must have its own icon, not reuse '
            'the offline add-waypoint action');
    expect(find.byTooltip('AI: Weather safety briefing'), findsOneWidget);
  });

  testWidgets('with no cached weather, the dialog says so instead of '
      'guessing', (tester) async {
    await pumpScreen(tester);

    await tester.tap(find.byIcon(Icons.auto_awesome));
    await tester.pump();
    await tester.pump();
    await tester.pump();

    expect(find.byType(PassageWeatherBriefingDialog), findsOneWidget);
    expect(find.textContaining('No cached weather yet'), findsOneWidget);
  });

  testWidgets('with cached weather but no key configured, asking says so '
      'instead of silently failing', (tester) async {
    await pumpScreen(tester, cachedWeather: sampleBundle());

    await tester.tap(find.byIcon(Icons.auto_awesome));
    await tester.pump();
    await tester.pump();
    await tester.pump();
    await tester.pump();

    expect(find.textContaining('No AI API key is configured'), findsOneWidget);
    expect(find.text('Go to Settings'), findsOneWidget);
  });
}
