import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:sisu_mate/services/marine_hazard_service.dart';

/// #239: marine hazard / gale & storm advisory feed (NOAA/NWS). Response
/// shape below mirrors a real live response confirmed before implementing.
void main() {
  String featureFor(String event, {String severity = 'Severe'}) => '''
{
  "properties": {
    "event": "$event",
    "severity": "$severity",
    "headline": "$event issued for Test Area",
    "areaDesc": "Test Area Waters",
    "effective": "2026-08-03T17:09:00-04:00",
    "expires": "2026-08-03T23:00:00-04:00",
    "description": "Test description"
  }
}''';

  group('parseMarineHazardAlertsJson', () {
    test('keeps marine-relevant events (Gale Warning, Small Craft '
        'Advisory) and drops unrelated ones (Heat Advisory)', () {
      final body = jsonEncode({
        'features': [
          jsonDecode(featureFor('Gale Warning')),
          jsonDecode(featureFor('Small Craft Advisory')),
          jsonDecode(featureFor('Heat Advisory')),
        ],
      });
      final alerts = parseMarineHazardAlertsJson(body);
      expect(alerts, hasLength(2));
      expect(alerts.map((a) => a.event),
          containsAll(['Gale Warning', 'Small Craft Advisory']));
      expect(alerts.any((a) => a.event == 'Heat Advisory'), isFalse);
    });

    test('maps fields correctly, including parsed effective/expires', () {
      final body = jsonEncode({
        'features': [jsonDecode(featureFor('Storm Warning'))],
      });
      final alert = parseMarineHazardAlertsJson(body).single;
      expect(alert.severity, 'Severe');
      expect(alert.areaDesc, 'Test Area Waters');
      expect(alert.effective, isNotNull);
      expect(alert.expires, isNotNull);
    });

    test('no active alerts (empty features) yields an empty list, not an '
        'error', () {
      final body = jsonEncode({'features': <dynamic>[]});
      expect(parseMarineHazardAlertsJson(body), isEmpty);
    });

    test('a tropical cyclone watch/warning passes the whitelist (NWS '
        'issues NHC advisories through the same feed)', () {
      final body = jsonEncode({
        'features': [jsonDecode(featureFor('Hurricane Warning'))],
      });
      expect(parseMarineHazardAlertsJson(body).single.event,
          'Hurricane Warning');
    });
  });

  group('MarineHazardService.fetchActiveAlerts', () {
    test('requests a point query with a User-Agent header', () async {
      Uri? capturedUri;
      Map<String, String>? capturedHeaders;
      final client = MockClient((request) async {
        capturedUri = request.url;
        capturedHeaders = request.headers;
        return http.Response(jsonEncode({'features': <dynamic>[]}), 200);
      });

      final alerts = await MarineHazardService()
          .fetchActiveAlerts(lat: 25.7617, lon: -80.1918, client: client);

      expect(alerts, isEmpty);
      expect(capturedUri!.host, 'api.weather.gov');
      expect(capturedUri!.path, '/alerts/active');
      expect(capturedUri!.queryParameters['point'], '25.7617,-80.1918');
      expect(capturedHeaders!['User-Agent'], isNotNull);
    });

    test('a real active alert round-trips through fetchActiveAlerts', () async {
      final client = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'features': [jsonDecode(featureFor('Small Craft Advisory'))],
          }),
          200,
        );
      });
      final alerts = await MarineHazardService()
          .fetchActiveAlerts(lat: 25.7617, lon: -80.1918, client: client);
      expect(alerts.single.event, 'Small Craft Advisory');
    });

    test('network failure returns an empty list, never throws', () async {
      final client = MockClient((request) async {
        throw Exception('offline');
      });
      final alerts = await MarineHazardService()
          .fetchActiveAlerts(lat: 25.7617, lon: -80.1918, client: client);
      expect(alerts, isEmpty);
    });

    test('HTTP non-200 returns an empty list, never throws', () async {
      final client = MockClient((request) async {
        return http.Response('error', 503);
      });
      final alerts = await MarineHazardService()
          .fetchActiveAlerts(lat: 25.7617, lon: -80.1918, client: client);
      expect(alerts, isEmpty);
    });
  });
}
