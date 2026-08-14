import 'dart:convert';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sisu_mate/core/di.dart';
import 'package:sisu_mate/core/units.dart';
import 'package:sisu_mate/data/drift/app_database.dart';
import 'package:sisu_mate/models/models.dart';
import 'package:sisu_mate/services/weather_service.dart';
import 'package:sisu_mate/ui/passage_handoff.dart';
import 'package:sisu_mate/ui/weather/passage_planner_screen.dart';

/// Widget-level coverage for the passage planner (TEST1b, "weather UI pump").
/// `WeatherScreen` itself isn't pumped here - its `initState` chains real
/// Geolocator / network. Passage planner only needs Riverpod for unit system.
void main() {
  // The default 800x600 test surface clips the 3rd waypoint editor below the
  // fold (a growing ListView + map + stats card overflow it), so `find.text`
  // (skipOffstage: true by default) can't see it. Use a tall surface instead
  // of scrolling, so every test can assert directly without extra drag steps.
  setUp(() {
    final binding = TestWidgetsFlutterBinding.ensureInitialized();
    binding.platformDispatcher.views.first.physicalSize = const Size(800, 2400);
    binding.platformDispatcher.views.first.devicePixelRatio = 1.0;
    addTearDown(binding.platformDispatcher.views.first.resetPhysicalSize);
    SharedPreferences.setMockInitialValues({});
  });

  Future<ProviderContainer> pumpPlanner(
    WidgetTester tester, {
    bool imperial = false,
    http.Client? weatherClient,
    ProviderContainer? existingContainer,
    PassageHandoff? handoff,
  }) async {
    final container = existingContainer ?? ProviderContainer();
    if (existingContainer == null) addTearDown(container.dispose);
    if (imperial) {
      container.read(unitPrefsProvider.notifier).restore(AppUnitPrefs.us);
    }
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: PassagePlannerScreen(
            weatherClient: weatherClient,
            handoff: handoff,
          ),
        ),
      ),
    );
    await tester.pump();
    return container;
  }

  testWidgets('#329: fromHook seeds start name; dest stays a generic waypoint',
      (tester) async {
    await pumpPlanner(
      tester,
      handoff: PassageHandoff.fromHook(lat: 26.5412, lon: -77.0634),
    );

    expect(find.widgetWithText(TextFormField, 'Hook'), findsOneWidget);
    expect(find.widgetWithText(TextFormField, 'Waypoint 1'), findsOneWidget);
    expect(find.widgetWithText(TextFormField, 'Marsh Harbour'), findsNothing);
  });

  testWidgets(
      '#329: toDestination seeds start + named dest (saved-spot contract)',
      (tester) async {
    await pumpPlanner(
      tester,
      handoff: PassageHandoff.toDestination(
        startName: 'Hook',
        startLat: 26.5412,
        startLon: -77.0634,
        destName: 'Marsh Harbour',
        destLat: 26.5410,
        destLon: -77.0600,
      ),
    );

    expect(find.widgetWithText(TextFormField, 'Hook'), findsOneWidget);
    expect(find.widgetWithText(TextFormField, 'Marsh Harbour'), findsOneWidget);
    expect(find.widgetWithText(TextFormField, 'Waypoint 1'), findsNothing);
  });

  testWidgets('#328: dest-only handoff still seeds the named destination',
      (tester) async {
    await pumpPlanner(
      tester,
      handoff: PassageHandoff.toDestination(
        destName: 'Marsh Harbour',
        destLat: 26.5410,
        destLon: -77.0600,
      ),
    );

    expect(find.widgetWithText(TextFormField, 'Marsh Harbour'), findsOneWidget);
    expect(find.widgetWithText(TextFormField, 'Departure'), findsOneWidget);
  });

  testWidgets('shows two default waypoints and a computed passage summary',
      (tester) async {
    await pumpPlanner(tester);

    expect(find.text('Passage Planner'), findsOneWidget);
    expect(find.widgetWithText(TextFormField, 'Departure'), findsOneWidget);
    expect(find.widgetWithText(TextFormField, 'Waypoint 1'), findsOneWidget);
    expect(find.text('Distance'), findsOneWidget);
    expect(find.text('ETA'), findsOneWidget);
    expect(find.text('Fuel'), findsOneWidget);
    expect(find.widgetWithText(TextField, 'Fuel L/h'), findsOneWidget);
    expect(find.widgetWithText(TextField, 'Speed (kn)'), findsOneWidget);
    // No delete button with only 2 waypoints (minimum kept).
    expect(find.byIcon(Icons.delete_outline), findsNothing);
  });

  testWidgets(
      '#265 — map shows numbered long-press waypoint handles (not MarkerLayer)',
      (tester) async {
    await pumpPlanner(tester);
    // Handles are numbered 1, 2 for the two default waypoints.
    expect(find.text('1'), findsWidgets);
    expect(find.text('2'), findsWidgets);
    // GestureDetectors host the long-press-then-drag handles.
    expect(find.byType(GestureDetector), findsWidgets);
  });

  testWidgets('SUG3: US unit prefs label fuel as gal/h', (tester) async {
    await pumpPlanner(tester, imperial: true);
    expect(find.widgetWithText(TextField, 'Fuel gal/h'), findsOneWidget);
  });

  testWidgets('Add waypoint appends a new stop and enables delete on all rows',
      (tester) async {
    await pumpPlanner(tester);

    await tester.tap(find.byTooltip('Add waypoint'));
    await tester.pump();

    expect(find.widgetWithText(TextFormField, 'Waypoint 2'), findsOneWidget);
    expect(find.byIcon(Icons.delete_outline), findsNWidgets(3));
  });

  testWidgets('changing speed updates the field and recomputes without crashing',
      (tester) async {
    await pumpPlanner(tester);

    await tester.enterText(find.widgetWithText(TextField, 'Speed (kn)'), '12');
    await tester.pump();

    final speedField =
        tester.widget<TextField>(find.widgetWithText(TextField, 'Speed (kn)'));
    expect(speedField.controller!.text, '12');
    expect(find.text('ETA'), findsOneWidget);
  });

  // #237: route-timeline forecast (weather at each waypoint's ETA).
  group('cumulativeNmToWaypoint / closestHourlyForEta (pure functions)', () {
    test('cumulativeNmToWaypoint sums leg distances up to index, 0 at the '
        'first waypoint', () {
      final wps = [
        (lat: 0.0, lon: 0.0),
        (lat: 1.0, lon: 0.0),
        (lat: 2.0, lon: 0.0),
      ];
      expect(cumulativeNmToWaypoint(wps, 0), 0);
      final toSecond = cumulativeNmToWaypoint(wps, 1);
      final toThird = cumulativeNmToWaypoint(wps, 2);
      expect(toSecond, greaterThan(0));
      expect(toThird, closeTo(toSecond * 2, 0.5));
    });

    test('closestHourlyForEta returns the nearest hour within tolerance',
        () {
      final target = DateTime(2026, 7, 9, 14, 10);
      final hourly = [
        HourlyWeather(time: DateTime(2026, 7, 9, 13), windMs: 5),
        HourlyWeather(time: DateTime(2026, 7, 9, 14), windMs: 8),
        HourlyWeather(time: DateTime(2026, 7, 9, 15), windMs: 12),
      ];
      final match = closestHourlyForEta(hourly, target);
      expect(match, isNotNull);
      expect(match!.windMs, 8);
    });

    test('closestHourlyForEta returns null when the ETA falls beyond the '
        'fetched forecast range — never a stale/wrong match', () {
      final target = DateTime(2026, 7, 12, 9);
      final hourly = [
        HourlyWeather(time: DateTime(2026, 7, 9, 13), windMs: 5),
        HourlyWeather(time: DateTime(2026, 7, 9, 14), windMs: 8),
      ];
      expect(closestHourlyForEta(hourly, target), isNull);
    });

    test('closestHourlyForEta returns null for an empty hourly list', () {
      expect(closestHourlyForEta(const [], DateTime(2026, 7, 9)), isNull);
    });
  });

  testWidgets(
      '#237: Route forecast shows the ETA-matched hour for a near waypoint '
      'and degrades gracefully to "beyond forecast range" for one with no '
      'matching data', (tester) async {
    final now = DateTime.now();
    final hour0 = DateTime(now.year, now.month, now.day, now.hour);
    final hour1 = hour0.add(const Duration(hours: 1));
    String hh(DateTime t) => t.toIso8601String().substring(0, 16);

    var forecastCalls = 0;
    final client = MockClient((request) async {
      switch (request.url.host) {
        case 'api.open-meteo.com':
          final call = forecastCalls++;
          if (call == 0) {
            // Departure (ETA ~0): a near match must be found.
            return http.Response(
              jsonEncode({
                'hourly': {
                  'time': [hh(hour0), hh(hour1)],
                  'wind_speed_10m': [8.0, 9.0],
                  'wind_direction_10m': [200.0, 205.0],
                  'wind_gusts_10m': [10.0, 11.0],
                  'precipitation_probability': [5, 6],
                },
                'daily': {'time': <String>[]},
              }),
              200,
            );
          }
          // The second waypoint: an empty hourly array forces the
          // "beyond forecast range" degrade path deterministically,
          // regardless of the actual computed ETA/test timing.
          return http.Response(
            jsonEncode({
              'hourly': {'time': <String>[]},
              'daily': {'time': <String>[]},
            }),
            200,
          );
        case 'marine-api.open-meteo.com':
          return http.Response(
            jsonEncode({
              'hourly': {'time': <String>[]}
            }),
            200,
          );
        case 'nominatim.openstreetmap.org':
          return http.Response(jsonEncode({'display_name': 'Test Place'}), 200);
        case 'api.opentopodata.org':
          return http.Response(
              jsonEncode({
                'results': [
                  {
                    'elevation': -10.0,
                    'location': {'lat': 1, 'lng': 2}
                  }
                ]
              }),
              200);
        default:
          return http.Response('not found', 404);
      }
    });

    await pumpPlanner(tester, weatherClient: client);
    await tester.tap(find.text('Route forecast'));
    // Not pumpAndSettle: the button shows an indeterminate
    // CircularProgressIndicator while loading, which never "settles".
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 20));
    }

    expect(find.textContaining('At ETA'), findsOneWidget,
        reason: 'the departure waypoint (ETA ~now) must find a near match');
    expect(find.textContaining('Beyond forecast range'), findsOneWidget,
        reason: 'a waypoint with no matching hourly data must degrade '
            'gracefully, never crash or show a stale match');
  });

  const computeRouteTooltip = 'Compute isochrone route (needs boat polar data)';

  http.Client mockForecastClient() => MockClient((request) async {
        switch (request.url.host) {
          case 'api.open-meteo.com':
            return http.Response(
              jsonEncode({
                'hourly': {
                  'time': ['2026-07-09T12:00'],
                  'wind_speed_10m': [10.0],
                  'wind_direction_10m': [200.0],
                  'wind_gusts_10m': [12.0],
                  'precipitation_probability': [5],
                },
                'daily': {'time': <String>[]},
              }),
              200,
            );
          case 'marine-api.open-meteo.com':
            return http.Response(
              jsonEncode({
                'hourly': {'time': <String>[]}
              }),
              200,
            );
          case 'nominatim.openstreetmap.org':
            return http.Response(jsonEncode({'display_name': 'Test Place'}), 200);
          case 'api.opentopodata.org':
            return http.Response(
                jsonEncode({
                  'results': [
                    {
                      'elevation': -10.0,
                      'location': {'lat': 1, 'lng': 2}
                    }
                  ]
                }),
                200);
          default:
            return http.Response('not found', 404);
        }
      });

  // #238: isochrone weather routing.
  testWidgets('#238: with no boat polar data configured, computing a route '
      'says so instead of guessing', (tester) async {
    await pumpPlanner(tester, weatherClient: mockForecastClient());

    await tester.tap(find.byTooltip(computeRouteTooltip));
    await tester.pump();

    expect(find.textContaining('Set boat polar data'), findsOneWidget);
  });

  testWidgets('#238: with boat polar data + wind, computes and renders a '
      'second route polyline', (tester) async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    await db.into(db.boats).insert(BoatsCompanion.insert(
          supabaseId: const Value('boat_1'),
          name: const Value('Sisu'),
          polarJson: Value(encodePolarTable(const [
            PolarPoint(twaDeg: 90, twsKt: 10, boatSpeedKt: 6),
          ])),
        ));
    await db.into(db.userSettingsTable).insert(
          UserSettingsTableCompanion.insert(
            id: const Value(1),
            activeBoatSupabaseId: const Value('boat_1'),
          ),
        );
    final container = ProviderContainer(overrides: [
      appDatabaseProvider.overrideWithValue(db),
    ]);
    addTearDown(container.dispose);

    await pumpPlanner(
      tester,
      weatherClient: mockForecastClient(),
      existingContainer: container,
    );

    await tester.tap(find.byTooltip(computeRouteTooltip));
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 20));
    }

    final polylineLayer =
        tester.widget<PolylineLayer>(find.byType(PolylineLayer));
    expect(polylineLayer.polylines, hasLength(2),
        reason: 'the great-circle line plus the computed isochrone route');
  });
}
