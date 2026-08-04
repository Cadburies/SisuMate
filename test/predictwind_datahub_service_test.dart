import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:sisu_mate/services/predictwind_datahub_service.dart';

/// #256 — PredictWind Datahub connectivity. `dart-defines.json`'s
/// PREDICTWIND_HUB_* values aren't set in `flutter test` runs (no
/// --dart-define-from-file passed) — compile-time `String.fromEnvironment`
/// values can't be overridden at runtime, so every branch is exercised via
/// the test-only `baseUrlOverride`/`usernameOverride`/`passwordOverride`
/// constructor seam plus a `MockClient` standing in for the real host
/// (live-verified against the real "PW-Hub" device on 2026-08-04: LuCI
/// login at `POST /cgi-bin/luci` returns `302` + `Set-Cookie: sysauth=...`
/// on success; the authenticated NMEA status JSON lives at
/// `admin/services/nmead/nmead_status`).
void main() {
  test('not configured in the test environment (no dart-defines passed)',
      () {
    const service = PredictWindDatahubService();
    expect(service.isConfigured, isFalse);
  });

  test('checkConnection reports notConfigured without making a request',
      () async {
    var called = false;
    final client = MockClient((request) async {
      called = true;
      return http.Response('', 200);
    });
    const service = PredictWindDatahubService();

    final status = await service.checkConnection(client: client);

    expect(status.state, PredictWindHubConnectionState.notConfigured);
    expect(called, isFalse);
  });

  test('a configured Hub with no credentials reports missingCredentials',
      () async {
    var called = false;
    final client = MockClient((request) async {
      called = true;
      return http.Response('', 200);
    });
    const service =
        PredictWindDatahubService(baseUrlOverride: 'https://fake-hub.test');

    final status = await service.checkConnection(client: client);

    expect(status.state, PredictWindHubConnectionState.missingCredentials);
    expect(called, isFalse);
  });

  test('a successful LuCI login (302 + sysauth cookie) reports connected',
      () async {
    final client = MockClient((request) async {
      expect(request.method, 'POST');
      expect(request.url.toString(), 'https://fake-hub.test/cgi-bin/luci');
      expect(request.body, 'luci_username=user&luci_password=pass');
      return http.Response('', 302, headers: {
        'set-cookie':
            'sysauth=deadbeef1234; path=/cgi-bin/luci/; SameSite=Strict; HttpOnly; secure',
      });
    });
    const service = PredictWindDatahubService(
      baseUrlOverride: 'https://fake-hub.test',
      usernameOverride: 'user',
      passwordOverride: 'pass',
    );

    final status = await service.checkConnection(client: client);

    expect(status.state, PredictWindHubConnectionState.connected);
  });

  test('a rejected login (no Set-Cookie) reports authFailed', () async {
    final client = MockClient((request) async => http.Response('', 403));
    const service = PredictWindDatahubService(
      baseUrlOverride: 'https://fake-hub.test',
      usernameOverride: 'user',
      passwordOverride: 'wrong',
    );

    final status = await service.checkConnection(client: client);

    expect(status.state, PredictWindHubConnectionState.authFailed);
  });

  test('a thrown error (timeout/connection refused) reports unreachable',
      () async {
    final client = MockClient((request) async {
      throw Exception('connection refused');
    });
    const service = PredictWindDatahubService(
      baseUrlOverride: 'https://fake-hub.test',
      usernameOverride: 'user',
      passwordOverride: 'pass',
    );

    final status = await service.checkConnection(client: client);

    expect(status.state, PredictWindHubConnectionState.unreachable);
    expect(status.detail, contains('connection refused'));
  });

  test('fetchBoatData with no credentials returns null without a request',
      () async {
    var called = false;
    final client = MockClient((request) async {
      called = true;
      return http.Response('', 200);
    });
    const service =
        PredictWindDatahubService(baseUrlOverride: 'https://fake-hub.test');

    final data = await service.fetchBoatData(client: client);

    expect(data, isNull);
    expect(called, isFalse);
  });

  test('fetchBoatData logs in then parses the real nmead_status JSON shape',
      () async {
    final client = MockClient((request) async {
      if (request.method == 'POST') {
        return http.Response('', 302,
            headers: {'set-cookie': 'sysauth=abc123; path=/cgi-bin/luci/'});
      }
      expect(request.url.toString(),
          'https://fake-hub.test/cgi-bin/luci/admin/services/nmead/nmead_status');
      expect(request.headers['Cookie'], 'sysauth=abc123');
      return http.Response(
        '{"lat":12.005442,"lon":-61.731507,"tws":6.837343,'
        '"twd":115.384747,"unixtime":1785872083,"sog":0.116631}',
        200,
      );
    });
    const service = PredictWindDatahubService(
      baseUrlOverride: 'https://fake-hub.test',
      usernameOverride: 'user',
      passwordOverride: 'pass',
    );

    final data = await service.fetchBoatData(client: client);

    expect(data, isNotNull);
    expect(data!.latitude, 12.005442);
    expect(data.longitude, -61.731507);
    expect(data.windSpeedKt, 6.837343);
    expect(data.windDirectionDeg, 115.384747);
    expect(data.observedAt, DateTime.fromMillisecondsSinceEpoch(1785872083000, isUtc: true));
  });

  test('fetchBoatData returns null when login fails', () async {
    final client = MockClient((request) async => http.Response('', 403));
    const service = PredictWindDatahubService(
      baseUrlOverride: 'https://fake-hub.test',
      usernameOverride: 'user',
      passwordOverride: 'wrong',
    );

    final data = await service.fetchBoatData(client: client);

    expect(data, isNull);
  });

  test('fetchBoatData returns null on a malformed/non-JSON status response',
      () async {
    final client = MockClient((request) async {
      if (request.method == 'POST') {
        return http.Response('', 302,
            headers: {'set-cookie': 'sysauth=abc123; path=/cgi-bin/luci/'});
      }
      return http.Response('not json', 200);
    });
    const service = PredictWindDatahubService(
      baseUrlOverride: 'https://fake-hub.test',
      usernameOverride: 'user',
      passwordOverride: 'pass',
    );

    final data = await service.fetchBoatData(client: client);

    expect(data, isNull);
  });
}
