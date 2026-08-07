import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:sisu_mate/services/home_assistant_service.dart';

void main() {
  group('HomeAssistantService', () {
    test('probeConnection succeeds on GET /api/ 200', () async {
      final client = MockClient((request) async {
        expect(request.url.path, '/api/');
        expect(request.headers['Authorization'], 'Bearer tok123');
        return http.Response('{"message":"API running."}', 200);
      });
      const svc = HomeAssistantService(
        baseUrl: 'http://ha.local:8123',
        token: 'tok123',
      );

      final r = await svc.probeConnection(client: client);
      expect(r.ok, isTrue);
      expect(r.detail, contains('Home Assistant'));
    });

    test('probeConnection reports bad token as auth failure', () async {
      final client = MockClient((request) async {
        return http.Response('{"message":"Unauthorized"}', 401);
      });
      const svc = HomeAssistantService(
        baseUrl: 'http://ha.local:8123',
        token: 'bad',
      );

      final r = await svc.probeConnection(client: client);
      expect(r.ok, isFalse);
      expect(r.detail!.toLowerCase(), contains('token'));
    });

    test('fetchBoatData reads lat/lon attributes from GPS entity', () async {
      final client = MockClient((request) async {
        expect(request.url.path, '/api/states/device_tracker.boat');
        return http.Response(
          '''
          {
            "entity_id": "device_tracker.boat",
            "state": "home",
            "last_updated": "${DateTime.now().toUtc().toIso8601String()}",
            "attributes": {
              "latitude": 12.5,
              "longitude": -61.4
            }
          }
          ''',
          200,
        );
      });
      const svc = HomeAssistantService(
        baseUrl: 'http://ha.local:8123',
        token: 'tok',
        gpsEntity: 'device_tracker.boat',
      );

      final data = await svc.fetchBoatData(
        client: client,
        viaLocalNetwork: true,
      );
      expect(data, isNotNull);
      expect(data!.latitude, 12.5);
      expect(data.longitude, -61.4);
      expect(data.viaLocalNetwork, isTrue);
      expect(data.hasFix, isTrue);
      expect(data.sourceLabel, contains('Home Assistant'));
    });

    test('fetchBoatData uses separate lat/lon sensors', () async {
      final client = MockClient((request) async {
        final id = request.url.pathSegments.last;
        if (id == 'sensor.lat') {
          return http.Response(
            '{"entity_id":"sensor.lat","state":"10.1","last_updated":"${DateTime.now().toUtc().toIso8601String()}"}',
            200,
          );
        }
        if (id == 'sensor.lon') {
          return http.Response(
            '{"entity_id":"sensor.lon","state":"-20.2","last_updated":"${DateTime.now().toUtc().toIso8601String()}"}',
            200,
          );
        }
        return http.Response('missing', 404);
      });
      const svc = HomeAssistantService(
        baseUrl: 'http://ha.local:8123',
        token: 'tok',
        latEntity: 'sensor.lat',
        lonEntity: 'sensor.lon',
      );

      final data = await svc.fetchBoatData(client: client);
      expect(data!.latitude, closeTo(10.1, 0.001));
      expect(data.longitude, closeTo(-20.2, 0.001));
    });

    test('not configured when token missing', () {
      const svc = HomeAssistantService(baseUrl: 'http://ha.local:8123');
      expect(svc.isConfigured, isFalse);
    });

    test('#312 probeConnection DNS fail on .local suggests LAN IP', () async {
      final client = MockClient((request) async {
        throw const SocketException(
          'Failed host lookup: \'homeassistant.local\'',
        );
      });
      const svc = HomeAssistantService(
        baseUrl: 'http://homeassistant.local:8123',
        token: 'tok',
      );

      final r = await svc.probeConnection(client: client);
      expect(r.ok, isFalse);
      expect(r.detail!.toLowerCase(), contains('mdns'));
      expect(r.detail, contains('192.168'));
      expect(r.detail, contains('homeassistant.local'));
    });

    test('#312 probeConnection accepts plain IP base URL shape', () async {
      final client = MockClient((request) async {
        expect(request.url.host, '192.168.0.20');
        expect(request.url.port, 8123);
        return http.Response('{"message":"API running."}', 200);
      });
      const svc = HomeAssistantService(
        baseUrl: 'http://192.168.0.20:8123',
        token: 'tok',
      );
      final r = await svc.probeConnection(client: client);
      expect(r.ok, isTrue);
      expect(r.detail, contains('192.168.0.20'));
    });
  });
}
