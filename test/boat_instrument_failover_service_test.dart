import 'package:connectivity_plus_platform_interface/connectivity_plus_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:sisu_mate/models/models.dart';
import 'package:sisu_mate/services/boat_instrument_failover_service.dart';
import 'package:sisu_mate/services/predictwind_datahub_service.dart';

class _FakeConnectivity extends ConnectivityPlatform
    with MockPlatformInterfaceMixin {
  _FakeConnectivity(this.results);
  final List<ConnectivityResult> results;

  @override
  Future<List<ConnectivityResult>> checkConnectivity() async => results;

  @override
  Stream<List<ConnectivityResult>> get onConnectivityChanged =>
      Stream.value(results);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  http.Response hubLoginOk() => http.Response(
        '',
        302,
        headers: {'set-cookie': 'sysauth=abc; path=/'},
      );

  String nmeadJson({double lat = 12.0, double lon = -61.0}) =>
      '{"lat":$lat,"lon":$lon,"quality":1,"tws":8,"twd":180,'
      '"unixtime":${DateTime.now().toUtc().millisecondsSinceEpoch ~/ 1000}}';

  group('BoatInstrumentFailoverService', () {
    test('on WiFi prefers DataHub local over HA when local Hub has fix',
        () async {
      ConnectivityPlatform.instance =
          _FakeConnectivity([ConnectivityResult.wifi]);

      final client = MockClient((request) async {
        final host = request.url.host;
        if (host == 'local-hub.test') {
          if (request.method == 'POST') return hubLoginOk();
          return http.Response(nmeadJson(lat: 1.0, lon: 2.0), 200);
        }
        if (host == 'ha-local.test') {
          // HA would work, but should not be needed.
          return http.Response(
            '{"entity_id":"device_tracker.boat","state":"home",'
            '"last_updated":"${DateTime.now().toUtc().toIso8601String()}",'
            '"attributes":{"latitude":9.0,"longitude":9.0}}',
            200,
          );
        }
        throw Exception('unexpected ${request.url}');
      });

      const hub = PredictWindDatahubService(
        localBaseUrlOverride: 'http://local-hub.test',
        baseUrlOverride: 'http://remote-hub.test',
        usernameOverride: 'u',
        passwordOverride: 'p',
      );
      final settings = UserSettings()
        ..homeAssistantUrl = 'http://ha-local.test'
        ..homeAssistantToken = 'tok'
        ..homeAssistantGpsEntity = 'device_tracker.boat';

      const svc = BoatInstrumentFailoverService();
      final snap = await svc.fetch(
        settings: settings,
        hubService: hub,
        client: client,
      );

      expect(snap.hasFix, isTrue);
      expect(snap.activeSource, BoatInstrumentSource.dataHubLocal);
      expect(snap.boatData!.latitude, 1.0);
    });

    test('off WiFi skips local and uses DataHub remote (beach bar)', () async {
      ConnectivityPlatform.instance =
          _FakeConnectivity([ConnectivityResult.mobile]);

      final seen = <String>[];
      final client = MockClient((request) async {
        seen.add(request.url.host);
        if (request.url.host == 'remote-hub.test') {
          if (request.method == 'POST') return hubLoginOk();
          return http.Response(nmeadJson(lat: 3.0, lon: 4.0), 200);
        }
        if (request.url.host == 'local-hub.test') {
          fail('must not try local Hub off WiFi');
        }
        throw Exception('unexpected ${request.url}');
      });

      const hub = PredictWindDatahubService(
        localBaseUrlOverride: 'http://local-hub.test',
        baseUrlOverride: 'http://remote-hub.test',
        usernameOverride: 'u',
        passwordOverride: 'p',
      );

      const svc = BoatInstrumentFailoverService();
      final snap = await svc.fetch(
        settings: UserSettings(),
        hubService: hub,
        client: client,
      );

      expect(snap.hasFix, isTrue);
      expect(snap.activeSource, BoatInstrumentSource.dataHubRemote);
      expect(seen.any((h) => h == 'local-hub.test'), isFalse);
    });

    test('falls through to HA remote when DataHub fails', () async {
      ConnectivityPlatform.instance =
          _FakeConnectivity([ConnectivityResult.mobile]);

      final client = MockClient((request) async {
        if (request.url.host == 'remote-hub.test') {
          throw Exception('connection refused');
        }
        if (request.url.host == 'ha-remote.test') {
          if (request.url.path == '/api/') {
            return http.Response('{"message":"API running."}', 200);
          }
          if (request.url.path.contains('device_tracker.boat')) {
            return http.Response(
              '{"entity_id":"device_tracker.boat","state":"not_home",'
              '"last_updated":"${DateTime.now().toUtc().toIso8601String()}",'
              '"attributes":{"latitude":5.5,"longitude":-6.6}}',
              200,
            );
          }
        }
        throw Exception('unexpected ${request.url}');
      });

      const hub = PredictWindDatahubService(
        baseUrlOverride: 'http://remote-hub.test',
        usernameOverride: 'u',
        passwordOverride: 'p',
      );
      final settings = UserSettings()
        ..homeAssistantRemoteUrl = 'http://ha-remote.test'
        ..homeAssistantToken = 'tok'
        ..homeAssistantGpsEntity = 'device_tracker.boat';

      const svc = BoatInstrumentFailoverService();
      final snap = await svc.fetch(
        settings: settings,
        hubService: hub,
        client: client,
      );

      expect(snap.hasFix, isTrue);
      expect(snap.activeSource, BoatInstrumentSource.homeAssistantRemote);
      expect(snap.boatData!.latitude, 5.5);
    });

    test('plannedSources orders local before internet on WiFi', () async {
      ConnectivityPlatform.instance =
          _FakeConnectivity([ConnectivityResult.wifi]);
      const hub = PredictWindDatahubService(
        localBaseUrlOverride: 'http://local-hub.test',
        baseUrlOverride: 'http://remote-hub.test',
        usernameOverride: 'u',
        passwordOverride: 'p',
      );
      final settings = UserSettings()
        ..homeAssistantUrl = 'http://ha.local'
        ..homeAssistantRemoteUrl = 'https://ha.remote'
        ..homeAssistantToken = 'tok'
        ..homeAssistantGpsEntity = 'device_tracker.boat';

      const svc = BoatInstrumentFailoverService();
      final plan = await svc.plannedSources(
        settings: settings,
        hubService: hub,
      );

      expect(plan.first, BoatInstrumentSource.dataHubLocal);
      expect(plan, contains(BoatInstrumentSource.homeAssistantLocal));
      expect(plan, contains(BoatInstrumentSource.dataHubRemote));
      expect(plan.last, BoatInstrumentSource.homeAssistantRemote);
      // Local sources appear before internet sources.
      final iLocalHa = plan.indexOf(BoatInstrumentSource.homeAssistantLocal);
      final iRemoteHub = plan.indexOf(BoatInstrumentSource.dataHubRemote);
      expect(iLocalHa, lessThan(iRemoteHub));
    });
  });
}
