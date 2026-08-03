import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sisu_mate/services/tide_service.dart';

/// #234: tide/current predictions (NOAA CO-OPS). Response shapes below
/// mirror real live responses confirmed before implementing.
void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('parseStationsJson', () {
    test('maps NOAA mdapi station entries (lat/lng -> lat/lon)', () {
      const body = '''
{"count":2,"stations":[
  {"id":"8454000","name":"Providence","lat":41.807,"lng":-71.401},
  {"id":"8447930","name":"Woods Hole","lat":41.5233,"lng":-70.6717}
]}''';
      final stations = parseStationsJson(body);
      expect(stations, hasLength(2));
      expect(stations.first.id, '8454000');
      expect(stations.first.name, 'Providence');
      expect(stations.first.lat, closeTo(41.807, 0.001));
      expect(stations.first.lon, closeTo(-71.401, 0.001));
    });
  });

  group('parseTidePredictionsJson', () {
    test('maps hilo predictions', () {
      const body = '''
{"predictions":[
  {"t":"2026-08-03 05:02", "v":"0.198", "type":"L"},
  {"t":"2026-08-03 12:04", "v":"4.774", "type":"H"}
]}''';
      final preds = parseTidePredictionsJson(body);
      expect(preds, hasLength(2));
      expect(preds[0].type, 'L');
      expect(preds[0].heightFt, closeTo(0.198, 0.001));
      expect(preds[1].type, 'H');
      expect(preds[1].time, DateTime(2026, 8, 3, 12, 4));
    });

    test('an error response (invalid station) degrades to an empty list, '
        'not a crash', () {
      const body = '{"error": {"message":"Wrong Station ID"}}';
      expect(parseTidePredictionsJson(body), isEmpty);
    });
  });

  group('parseCurrentPredictionsJson', () {
    test('maps slack/ebb/flood current predictions', () {
      const body = '''
{"current_predictions":{"units":"feet, knots","cp":[
  {"Type":"slack","meanFloodDir":210,"meanEbbDir":40,"Time":"2026-08-03 03:12","Velocity_Major":0},
  {"Type":"ebb","meanFloodDir":210,"meanEbbDir":40,"Time":"2026-08-03 06:19","Velocity_Major":-2.88}
]}}''';
      final preds = parseCurrentPredictionsJson(body);
      expect(preds, hasLength(2));
      expect(preds[0].type, 'slack');
      expect(preds[1].type, 'ebb');
      expect(preds[1].velocityKt, closeTo(-2.88, 0.001));
      expect(preds[1].meanFloodDirDeg, 210);
      expect(preds[1].meanEbbDirDeg, 40);
    });

    test('an error response degrades to an empty list', () {
      const body = '{"error": {"message":"Wrong Station ID"}}';
      expect(parseCurrentPredictionsJson(body), isEmpty);
    });
  });

  group('nearestStation', () {
    const stations = [
      TideStation(id: 'a', name: 'A', lat: 0, lon: 0),
      TideStation(id: 'b', name: 'B', lat: 0, lon: 1),
      TideStation(id: 'c', name: 'C', lat: 10, lon: 10),
    ];

    test('returns the closest station within range', () {
      final s = nearestStation(stations, 0.01, 0.01);
      expect(s?.id, 'a');
    });

    test('returns null when nothing is within maxNm — graceful "no '
        'coverage", not an error', () {
      final s = nearestStation(stations, 45, 45, maxNm: 100);
      expect(s, isNull);
    });

    test('returns null for an empty station list', () {
      expect(nearestStation(const [], 0, 0), isNull);
    });
  });

  group('TideService', () {
    test('fetchTideStations caches after the first fetch — a second call '
        'makes no network request', () async {
      var calls = 0;
      final client = MockClient((request) async {
        calls++;
        return http.Response(
          jsonEncode({
            'stations': [
              {'id': 'x', 'name': 'X', 'lat': 1.0, 'lng': 2.0},
            ],
          }),
          200,
        );
      });
      final service = TideService();

      final first = await service.fetchTideStations(client: client);
      expect(first, hasLength(1));
      expect(calls, 1);

      final second = await service.fetchTideStations(client: client);
      expect(second, hasLength(1));
      expect(calls, 1, reason: 'cached station list must not refetch');
    });

    test('fetchTideStations falls back to any cache on network failure',
        () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        'tide_stations_v1',
        jsonEncode({
          'fetchedAt': DateTime.now().toIso8601String(),
          'stations': [
            {'id': 'cached', 'name': 'Cached Station', 'lat': 1.0, 'lon': 2.0},
          ],
        }),
      );
      final client = MockClient((request) async {
        throw Exception('offline');
      });
      final service = TideService();
      final stations = await service.fetchTideStations(client: client);
      expect(stations, hasLength(1));
      expect(stations.single.id, 'cached');
    });

    test('fetchTidePredictions returns an empty list on network failure, '
        'never throws', () async {
      final client = MockClient((request) async {
        throw Exception('offline');
      });
      final service = TideService();
      final preds =
          await service.fetchTidePredictions(stationId: '8454000', client: client);
      expect(preds, isEmpty);
    });
  });
}
