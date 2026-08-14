import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sisu_mate/models/models.dart';
import 'package:sisu_mate/services/predictwind_datahub_service.dart';
import 'package:sisu_mate/ui/anchor/anchor_info_panel.dart';

/// #305 — Info tab shows live instrument depth independent of GPS fix.
/// HA-screen follow-up — air/water temperature, nearest tide station +
/// next high/low, and a 6-hour hourly forecast.
void main() {
  setUp(() {
    // TideService/WeatherService both cache via SharedPreferences.
    SharedPreferences.setMockInitialValues({});
  });

  PredictWindBoatData boat({
    double? depthMeters,
    double? lat,
    double? lon,
    double? airTempC,
    double? waterTempC,
  }) =>
      PredictWindBoatData(
        latitude: lat,
        longitude: lon,
        depthMeters: depthMeters,
        airTempC: airTempC,
        waterTempC: waterTempC,
        observedAt: DateTime.utc(2026, 8, 1),
      );

  /// The panel can render up to ~11 cards (margin/bearing/distance, depth,
  /// air/water temp, SOG/COG/wind, boat+anchor GPS, tide, forecast) — taller
  /// than the default 600px test viewport, and `ListView` (Sliver-backed)
  /// doesn't build children outside the viewport + cache extent, so a card
  /// far enough down silently isn't in the tree at all (no error, no
  /// warning — `find` just returns 0, indistinguishable from "genuinely not
  /// there" without checking). A larger surface avoids needing
  /// `scrollUntilVisible` before every assertion.
  Future<void> pumpPanel(WidgetTester tester, Widget panel) async {
    await tester.binding.setSurfaceSize(const Size(400, 2000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(home: Scaffold(body: panel)),
    );
  }

  /// A network double covering every host `AnchorInfoPanel`'s tide/weather
  /// fetch can reach — Open-Meteo (forecast + marine, both required not to
  /// throw or the whole forecast call fails), NOAA CO-OPS (stations +
  /// predictions), and a safe 404 fallback for the best-effort place-name/
  /// charted-depth enrichment calls (already wrapped in their own
  /// try/catch inside WeatherService, so a 404 there is harmless).
  http.Client fakeNetwork({
    List<Map<String, dynamic>> tideStations = const [],
    String tidePredictionsBody = '{"predictions":[]}',
  }) {
    return MockClient((request) async {
      final host = request.url.host;
      if (host == 'api.open-meteo.com') {
        final now = DateTime.now().toUtc();
        final hours = List.generate(
            8, (i) => now.add(Duration(hours: i)).toIso8601String());
        return http.Response(
          '{"current":{"temperature_2m":20},'
          '"hourly":{"time":${_jsonList(hours)},'
          '"temperature_2m":${_jsonList(List.filled(8, 21.0))},'
          '"wind_speed_10m":${_jsonList(List.filled(8, 5.0))},'
          '"wind_direction_10m":${_jsonList(List.filled(8, 180.0))},'
          '"wind_gusts_10m":${_jsonList(List.filled(8, 7.0))},'
          '"precipitation_probability":${_jsonList(List.filled(8, 10.0))}},'
          '"daily":{"time":[],"weather_code":[],"temperature_2m_max":[],'
          '"temperature_2m_min":[],"wind_speed_10m_max":[],'
          '"precipitation_sum":[]}}',
          200,
        );
      }
      if (host == 'marine-api.open-meteo.com') {
        return http.Response('{"hourly":{"time":[]}}', 200);
      }
      if (host == 'api.tidesandcurrents.noaa.gov' &&
          request.url.path.contains('stations.json')) {
        return http.Response(
          '{"stations":${_jsonList(tideStations)}}',
          200,
        );
      }
      if (host == 'api.tidesandcurrents.noaa.gov' &&
          request.url.path.contains('datagetter')) {
        return http.Response(tidePredictionsBody, 200);
      }
      return http.Response('not found', 404);
    });
  }

  testWidgets('shows depth when instruments report it (no GPS required)',
      (tester) async {
    await pumpPanel(
      tester,
      AnchorInfoPanel(
        activeWatch: null,
        boatData: boat(depthMeters: 7.5),
        positionLat: null,
        positionLon: null,
      ),
    );

    expect(find.text('Depth'), findsOneWidget);
    expect(find.text('7.5 m'), findsOneWidget);
    expect(
      find.text('Water depth below transducer (instruments)'),
      findsOneWidget,
    );
  });

  testWidgets('shows Unavailable when depth is missing', (tester) async {
    await pumpPanel(
      tester,
      AnchorInfoPanel(
        activeWatch: null,
        boatData: boat(lat: 12, lon: -61),
        positionLat: 12,
        positionLon: -61,
        positionSourceLabel: 'Phone GPS',
        httpClient: fakeNetwork(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Depth'), findsOneWidget);
    // Depth row uses the same "Unavailable" string as other empty metrics.
    expect(find.text('Unavailable'), findsWidgets);
    expect(
      find.text('Needs a depth reading from boat instruments.'),
      findsOneWidget,
    );
  });

  testWidgets('depth still shown when an active watch exists', (tester) async {
    final watch = AnchorWatch()
      ..id = 1
      ..anchorLat = 12
      ..anchorLon = -61
      ..radiusMeters = 30
      ..scopeRatio = 5;

    await pumpPanel(
      tester,
      AnchorInfoPanel(
        activeWatch: watch,
        boatData: boat(depthMeters: 6.0, lat: 12.0001, lon: -61),
        positionLat: 12.0001,
        positionLon: -61,
        positionSourceLabel: 'DataHub (local)',
        httpClient: fakeNetwork(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Depth'), findsOneWidget);
    expect(find.text('6.0 m'), findsOneWidget);
  });

  testWidgets('shows air and water temperature from instruments',
      (tester) async {
    await pumpPanel(
      tester,
      AnchorInfoPanel(
        activeWatch: null,
        boatData: boat(airTempC: 24.5, waterTempC: 19.0),
        positionLat: null,
        positionLon: null,
      ),
    );

    expect(find.text('Air temperature'), findsOneWidget);
    expect(find.text('24.5°C'), findsOneWidget);
    expect(find.text('Water temperature'), findsOneWidget);
    expect(find.text('19.0°C'), findsOneWidget);
  });

  testWidgets('temperature cards show Unavailable when instruments report '
      'nothing', (tester) async {
    await pumpPanel(
      tester,
      AnchorInfoPanel(
        activeWatch: null,
        boatData: boat(depthMeters: 5),
        positionLat: null,
        positionLon: null,
      ),
    );

    expect(find.text('Air temperature'), findsOneWidget);
    expect(find.text('Water temperature'), findsOneWidget);
    expect(find.text('Unavailable'), findsWidgets);
  });

  testWidgets('shows the nearest tide station with next high/low',
      (tester) async {
    final now = DateTime.now().toUtc();
    await pumpPanel(
      tester,
      AnchorInfoPanel(
        activeWatch: null,
        boatData: boat(lat: 12, lon: -61),
        positionLat: 12,
        positionLon: -61,
        httpClient: fakeNetwork(
          tideStations: [
            {'id': '1234567', 'name': 'Test Harbor', 'lat': 12.0, 'lng': -61.0},
          ],
          tidePredictionsBody: '{"predictions":['
              '{"t":"${_noaaFormat(now.add(const Duration(hours: 2)))}",'
              '"v":"3.1","type":"H"},'
              '{"t":"${_noaaFormat(now.add(const Duration(hours: 8)))}",'
              '"v":"0.4","type":"L"}'
              ']}',
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Test Harbor'), findsOneWidget);
    expect(find.text('Next high'), findsOneWidget);
    expect(find.text('Next low'), findsOneWidget);
    expect(find.textContaining('3.1 ft'), findsOneWidget);
    expect(find.textContaining('0.4 ft'), findsOneWidget);
  });

  testWidgets('tide card degrades to Unavailable with no nearby station',
      (tester) async {
    await pumpPanel(
      tester,
      AnchorInfoPanel(
        activeWatch: null,
        boatData: boat(lat: 12, lon: -61),
        positionLat: 12,
        positionLon: -61,
        httpClient: fakeNetwork(tideStations: const []),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Nearest tide station'), findsOneWidget);
    expect(
      find.textContaining('No NOAA station within range'),
      findsOneWidget,
    );
  });

  testWidgets('shows a 6-hour forecast strip', (tester) async {
    await pumpPanel(
      tester,
      AnchorInfoPanel(
        activeWatch: null,
        boatData: boat(lat: 12, lon: -61),
        positionLat: 12,
        positionLon: -61,
        httpClient: fakeNetwork(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Next 6 hours'), findsOneWidget);
    // 6 of the mocked 8 hourly entries are used.
    expect(find.text('21°'), findsNWidgets(6));
  });

  testWidgets('#329: hand-off buttons hidden without callbacks', (tester) async {
    final watch = AnchorWatch()
      ..id = 1
      ..anchorLat = 12
      ..anchorLon = -61
      ..radiusMeters = 30
      ..scopeRatio = 5;

    await pumpPanel(
      tester,
      AnchorInfoPanel(
        activeWatch: watch,
        boatData: boat(lat: 12, lon: -61),
        positionLat: 12,
        positionLon: -61,
        httpClient: fakeNetwork(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Plan passage from hook'), findsNothing);
    expect(find.text('Weather at hook'), findsNothing);
  });

  testWidgets('#329: hand-off buttons fire callbacks when provided',
      (tester) async {
    final watch = AnchorWatch()
      ..id = 1
      ..anchorLat = 12
      ..anchorLon = -61
      ..radiusMeters = 30
      ..scopeRatio = 5;
    var planned = 0;
    var weather = 0;

    await pumpPanel(
      tester,
      AnchorInfoPanel(
        activeWatch: watch,
        boatData: boat(lat: 12, lon: -61),
        positionLat: 12,
        positionLon: -61,
        httpClient: fakeNetwork(),
        onPlanPassage: () => planned++,
        onOpenWeather: () => weather++,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Plan passage from hook'));
    await tester.tap(find.text('Weather at hook'));
    expect(planned, 1);
    expect(weather, 1);
  });

  testWidgets('no network calls at all when no position is available',
      (tester) async {
    var called = false;
    final client = MockClient((request) async {
      called = true;
      return http.Response('not found', 404);
    });

    await pumpPanel(
      tester,
      AnchorInfoPanel(
        activeWatch: null,
        boatData: boat(depthMeters: 4),
        positionLat: null,
        positionLon: null,
        httpClient: client,
      ),
    );
    await tester.pumpAndSettle();

    expect(called, isFalse,
        reason: 'tide/weather enrichment needs a position; must not fire '
            'a request just because the panel rendered');
    expect(find.text('Next 6 hours'), findsNothing);
    expect(find.text('Nearest tide station'), findsNothing);
  });
}

String _jsonList(List<dynamic> items) {
  final buf = StringBuffer('[');
  for (var i = 0; i < items.length; i++) {
    if (i > 0) buf.write(',');
    final v = items[i];
    if (v is String) {
      buf.write('"$v"');
    } else if (v is Map) {
      buf.write('{');
      var first = true;
      for (final entry in v.entries) {
        if (!first) buf.write(',');
        first = false;
        final value = entry.value;
        buf.write('"${entry.key}":${value is String ? '"$value"' : value}');
      }
      buf.write('}');
    } else {
      buf.write(v);
    }
  }
  buf.write(']');
  return buf.toString();
}

/// NOAA datagetter's `t` field format: `yyyy-MM-dd HH:mm`.
String _noaaFormat(DateTime t) {
  final local = t.toLocal();
  String p2(int n) => n.toString().padLeft(2, '0');
  return '${local.year}-${p2(local.month)}-${p2(local.day)} '
      '${p2(local.hour)}:${p2(local.minute)}';
}
