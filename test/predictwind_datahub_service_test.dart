import 'dart:async';

import 'package:connectivity_plus_platform_interface/connectivity_plus_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
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
///
/// #263 — WiFi state (for the local-vs-remote failover) is faked via
/// `ConnectivityPlatform.instance`, the same swappable-singleton pattern
/// `location_service_test.dart` uses for `GeolocatorPlatform.instance`.
class _FakeConnectivityPlatform extends ConnectivityPlatform
    with MockPlatformInterfaceMixin {
  List<ConnectivityResult> result = [ConnectivityResult.none];

  @override
  Future<List<ConnectivityResult>> checkConnectivity() async => result;
}

void main() {
  late _FakeConnectivityPlatform fakeConnectivity;

  setUp(() {
    fakeConnectivity = _FakeConnectivityPlatform();
    ConnectivityPlatform.instance = fakeConnectivity;
  });


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

  test(
      'a thrown error (timeout/connection refused) reports unreachable with '
      'a friendly, not raw, detail', () async {
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
    // #270 — a real on-device report showed the raw ClientException/
    // SocketException string (errno, local ephemeral port, address) leaking
    // straight into the Hub status card. detail must be the friendly copy.
    expect(status.detail, "Connection refused — the Hub isn't accepting "
        'connections right now.');
  });

  group('#270 — friendlyConnectionError (no raw exception text to users)',
      () {
    test('maps a timeout', () {
      expect(
        friendlyConnectionError(TimeoutException('Future not completed')),
        'Timed out waiting for a response.',
      );
    });

    test('maps a connection-refused socket error', () {
      expect(
        friendlyConnectionError(Exception(
          'ClientException with SocketException: Connection refused (OS '
          'Error: Connection refused, errno = 61), address = '
          'remote.rdsensing.com, port = 51169',
        )),
        "Connection refused — the Hub isn't accepting connections right "
            'now.',
      );
    });

    test('maps a DNS lookup failure', () {
      // #312 — guide sailors toward LAN IP when hostname fails (phones/mDNS).
      expect(
        friendlyConnectionError(
            Exception('Failed host lookup: remote.rdsensing.com')),
        "Can't resolve that hostname — check spelling, or use the "
        'device IP on the boat network (e.g. http://192.168.0.20:8123).',
      );
    });

    test('maps a certificate/handshake failure', () {
      expect(
        friendlyConnectionError(Exception(
            'HandshakeException: CERTIFICATE_VERIFY_FAILED: self signed certificate')),
        'Secure connection failed.',
      );
    });

    test('falls back to a generic message for anything unrecognized', () {
      expect(
        friendlyConnectionError(Exception('some new never-seen-before error')),
        "Check the boat's network connection.",
      );
    });
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
        '"twd":115.384747,"unixtime":1785872083,"sog":0.116631,'
        '"cog":87.5,"aws":4.2,"awa":-32.1,"dpt":5.5}',
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
    // #266 — SOG/COG/AWS/AWA already present on the live Hub JSON.
    expect(data.sogKt, 0.116631);
    expect(data.cogDeg, 87.5);
    expect(data.apparentWindSpeedKt, 4.2);
    expect(data.apparentWindDirectionDeg, -32.1);
    expect(data.depthMeters, 5.5);
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

  group('GPS fix quality (#256 follow-up)', () {
    test('quality 0 (no fix) nulls out lat/lon instead of trusting them',
        () async {
      final client = MockClient((request) async {
        if (request.method == 'POST') {
          return http.Response('', 302,
              headers: {'set-cookie': 'sysauth=abc123; path=/cgi-bin/luci/'});
        }
        return http.Response(
          '{"lat":12.0,"lon":-61.7,"quality":0,'
          '"unixtime":${DateTime.now().toUtc().millisecondsSinceEpoch ~/ 1000}}',
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
      expect(data!.latitude, isNull);
      expect(data.longitude, isNull);
      expect(data.hasFix, isFalse);
    });

    test('a missing quality field is treated as unknown, not no-fix',
        () async {
      final client = MockClient((request) async {
        if (request.method == 'POST') {
          return http.Response('', 302,
              headers: {'set-cookie': 'sysauth=abc123; path=/cgi-bin/luci/'});
        }
        return http.Response(
          '{"lat":12.0,"lon":-61.7,'
          '"unixtime":${DateTime.now().toUtc().millisecondsSinceEpoch ~/ 1000}}',
          200,
        );
      });
      const service = PredictWindDatahubService(
        baseUrlOverride: 'https://fake-hub.test',
        usernameOverride: 'user',
        passwordOverride: 'pass',
      );

      final data = await service.fetchBoatData(client: client);

      expect(data!.latitude, 12.0);
      expect(data.hasFix, isTrue);
    });
  });

  group('PredictWindBoatData.isStale/hasFix (#256 follow-up)', () {
    test('a fresh reading is not stale', () {
      final data = PredictWindBoatData(
        latitude: 12.0,
        longitude: -61.7,
        observedAt: DateTime.now().toUtc(),
      );
      expect(data.isStale(), isFalse);
      expect(data.hasFix, isTrue);
    });

    test('a reading older than maxAge is stale, and loses its fix', () {
      final data = PredictWindBoatData(
        latitude: 12.0,
        longitude: -61.7,
        observedAt: DateTime.now().toUtc().subtract(const Duration(minutes: 5)),
      );
      expect(data.isStale(), isTrue);
      expect(data.hasFix, isFalse);
    });

    test('a null position never has a fix even if fresh', () {
      final data = PredictWindBoatData(observedAt: DateTime.now().toUtc());
      expect(data.isStale(), isFalse);
      expect(data.hasFix, isFalse);
    });
  });

  group('#263 — local-WiFi-first, internet-fallback failover', () {
    http.Response loginOk() => http.Response('', 302,
        headers: {'set-cookie': 'sysauth=abc123; path=/cgi-bin/luci/'});

    test('on WiFi, a working local Hub is used — remote is never tried',
        () async {
      fakeConnectivity.result = [ConnectivityResult.wifi];
      var remoteCalled = false;
      final client = MockClient((request) async {
        if (request.url.host == 'remote-hub.test') {
          remoteCalled = true;
          return loginOk();
        }
        expect(request.url.host, 'local-hub.test');
        return loginOk();
      });
      const service = PredictWindDatahubService(
        baseUrlOverride: 'https://remote-hub.test',
        localBaseUrlOverride: 'http://local-hub.test',
        usernameOverride: 'user',
        passwordOverride: 'pass',
      );

      final status = await service.checkConnection(client: client);

      expect(status.state, PredictWindHubConnectionState.connected);
      expect(status.viaLocalNetwork, isTrue);
      expect(remoteCalled, isFalse);
    });

    test('on WiFi, a failing local Hub falls back to remote', () async {
      fakeConnectivity.result = [ConnectivityResult.wifi];
      final client = MockClient((request) async {
        if (request.url.host == 'local-hub.test') {
          throw Exception('connection refused');
        }
        return loginOk();
      });
      const service = PredictWindDatahubService(
        baseUrlOverride: 'https://remote-hub.test',
        localBaseUrlOverride: 'http://local-hub.test',
        usernameOverride: 'user',
        passwordOverride: 'pass',
      );

      final status = await service.checkConnection(client: client);

      expect(status.state, PredictWindHubConnectionState.connected);
      expect(status.viaLocalNetwork, isFalse);
    });

    test('off WiFi (mobile data), local is never attempted — goes straight to remote',
        () async {
      fakeConnectivity.result = [ConnectivityResult.mobile];
      var localCalled = false;
      final client = MockClient((request) async {
        if (request.url.host == 'local-hub.test') {
          localCalled = true;
        }
        return loginOk();
      });
      const service = PredictWindDatahubService(
        baseUrlOverride: 'https://remote-hub.test',
        localBaseUrlOverride: 'http://local-hub.test',
        usernameOverride: 'user',
        passwordOverride: 'pass',
      );

      final status = await service.checkConnection(client: client);

      expect(status.state, PredictWindHubConnectionState.connected);
      expect(status.viaLocalNetwork, isFalse);
      expect(localCalled, isFalse);
    });

    test(
        'off WiFi with only a local Hub URL configured (no remote) reports '
        'unreachable without making any request', () async {
      fakeConnectivity.result = [ConnectivityResult.none];
      var called = false;
      final client = MockClient((request) async {
        called = true;
        return loginOk();
      });
      const service = PredictWindDatahubService(
        localBaseUrlOverride: 'http://local-hub.test',
        usernameOverride: 'user',
        passwordOverride: 'pass',
      );

      final status = await service.checkConnection(client: client);

      expect(status.state, PredictWindHubConnectionState.unreachable);
      expect(called, isFalse);
    });

    test('fetchBoatData reports viaLocalNetwork correctly for the local path',
        () async {
      fakeConnectivity.result = [ConnectivityResult.wifi];
      final client = MockClient((request) async {
        if (request.method == 'POST') return loginOk();
        return http.Response(
          '{"lat":12.0,"lon":-61.7,'
          '"unixtime":${DateTime.now().toUtc().millisecondsSinceEpoch ~/ 1000}}',
          200,
        );
      });
      const service = PredictWindDatahubService(
        baseUrlOverride: 'https://remote-hub.test',
        localBaseUrlOverride: 'http://local-hub.test',
        usernameOverride: 'user',
        passwordOverride: 'pass',
      );

      final data = await service.fetchBoatData(client: client);

      expect(data, isNotNull);
      expect(data!.viaLocalNetwork, isTrue);
    });
  });

  group('#263 — gateway setup: testConnection / discoverGateways', () {
    http.Response loginOk() => http.Response('', 302,
        headers: {'set-cookie': 'sysauth=abc123; path=/cgi-bin/luci/'});

    test('testConnection succeeds against a reachable address with a good '
        'login', () async {
      final client = MockClient((request) async {
        expect(request.url.toString(),
            'http://some-hub.test/cgi-bin/luci');
        expect(request.body, 'luci_username=user&luci_password=pass');
        return loginOk();
      });
      const service = PredictWindDatahubService();

      final ok = await service.testConnection(
        baseUrl: 'http://some-hub.test',
        username: 'user',
        password: 'pass',
        client: client,
      );

      expect(ok, isTrue);
    });

    test('probeConnection reports auth failure distinctly', () async {
      final client = MockClient((request) async => http.Response('', 403));
      const service = PredictWindDatahubService();

      final result = await service.probeConnection(
        baseUrl: 'http://some-hub.test',
        username: 'user',
        password: 'wrong',
        client: client,
      );

      expect(result.ok, isFalse);
      expect(result.detail, contains("Couldn't sign in"));
    });

    test('probeConnection reports friendly network errors', () async {
      final client = MockClient((request) async {
        throw Exception('connection refused');
      });
      const service = PredictWindDatahubService();

      final result = await service.probeConnection(
        baseUrl: 'http://unreachable.test',
        username: 'user',
        password: 'pass',
        client: client,
      );

      expect(result.ok, isFalse);
      expect(result.detail, isNotNull);
      expect(result.detail!.toLowerCase(), contains('refused'));
    });

    test('isPrivateLanUrl classifies boat LAN vs internet tunnels', () {
      expect(
        PredictWindDatahubService.isPrivateLanUrl('http://192.168.10.31'),
        isTrue,
      );
      expect(
        PredictWindDatahubService.isPrivateLanUrl('http://10.10.10.1'),
        isTrue,
      );
      expect(
        PredictWindDatahubService.isPrivateLanUrl(
            'http://remote.rdsensing.com:36121'),
        isFalse,
      );
      expect(
        PredictWindDatahubService.isPrivateLanUrl(
            'https://remote.rdsensing.com:36122'),
        isFalse,
      );
    });

    test('knownRemoteAddresses always includes the vendor HTTP tunnel', () {
      expect(
        PredictWindDatahubService.knownRemoteAddresses,
        contains('http://remote.rdsensing.com:36121'),
      );
    });

    test('defaults expose DataHub remote/local and YDWG-02', () {
      expect(
        PredictWindDatahubService.defaultDataHubRemoteUrl,
        'http://remote.rdsensing.com:36121',
      );
      expect(
        PredictWindDatahubService.defaultDataHubLocalUrl,
        startsWith('http://'),
      );
      expect(
        PredictWindDatahubService.defaultYdwgUrl,
        startsWith('http://'),
      );
      expect(
        PredictWindDatahubService.knownLocalAddresses.first,
        PredictWindDatahubService.defaultDataHubLocalUrl,
      );
      expect(
        PredictWindDatahubService.knownLocalAddresses,
        contains('http://10.10.10.1'),
      );
      expect(
        PredictWindDatahubService.boatLanDefaults.map((s) => s.kind),
        containsAll([
          GatewayDefaultKind.dataHubLocal,
          GatewayDefaultKind.ydwg,
        ]),
      );
      expect(
        PredictWindDatahubService.internetDefaults.single.kind,
        GatewayDefaultKind.dataHubRemote,
      );
    });

    test('discoverGateways does not put YDWG in Hub login hits', () async {
      final client = MockClient((request) async {
        // Anything on the YDWG host answers GET (reachability); LuCI fails.
        if (request.url.host ==
            Uri.parse(PredictWindDatahubService.defaultYdwgUrl).host) {
          return http.Response('ok', 200);
        }
        throw Exception('connection refused');
      });
      const service = PredictWindDatahubService();

      final result = await service.discoverGateways(
        username: 'user',
        password: 'pass',
        client: client,
      );

      expect(result.workingAddresses, isEmpty);
      expect(result.ydwgReachable, isTrue);
      expect(result.summary, contains('YDWG-02'));
    });

    test(
        'discoverGateways returns working local + remote addresses',
        () async {
      final client = MockClient((request) async {
        final host = request.url.host;
        // Local 10.10.10.1 and remote HTTP tunnel succeed; others fail.
        if (host == '10.10.10.1' ||
            (host == 'remote.rdsensing.com' && request.url.port == 36121)) {
          return loginOk();
        }
        throw Exception('connection refused');
      });
      const service = PredictWindDatahubService();

      final result = await service.discoverGateways(
        username: 'user',
        password: 'pass',
        client: client,
      );

      expect(result.workingAddresses, contains('http://10.10.10.1'));
      expect(
        result.workingAddresses,
        contains('http://remote.rdsensing.com:36121'),
      );
      expect(result.summary.toLowerCase(), contains('internet'));
    });

    test('discoverGateways returns empty + summary when nothing answers',
        () async {
      final client = MockClient((request) async {
        throw Exception('connection refused');
      });
      const service = PredictWindDatahubService();

      final result = await service.discoverGateways(
        username: 'user',
        password: 'pass',
        client: client,
      );

      expect(result.workingAddresses, isEmpty);
      expect(result.summary, isNotEmpty);
    });

    test('discoverLocalGateways only probes local addresses', () async {
      final seen = <String>[];
      final client = MockClient((request) async {
        seen.add(request.url.toString());
        if (request.url.host == '10.10.10.1') return loginOk();
        throw Exception('connection refused');
      });
      const service = PredictWindDatahubService();

      final found = await service.discoverLocalGateways(
        username: 'user',
        password: 'pass',
        client: client,
      );

      expect(found, contains('http://10.10.10.1'));
      expect(
        seen.any((u) => u.contains('remote.rdsensing.com')),
        isFalse,
      );
    });

    test('probeYdwgLogin succeeds on 204 + session cookie', () async {
      final client = MockClient((request) async {
        expect(request.method, 'POST');
        expect(request.url.path, '/login');
        expect(request.url.queryParameters['login'], 'admin');
        expect(request.url.queryParameters['password'], 'admin');
        return http.Response(
          '',
          204,
          headers: {'set-cookie': 'session=deadbeef; path=/'},
        );
      });
      const service = PredictWindDatahubService();

      final result = await service.probeYdwgLogin(
        baseUrl: 'http://192.168.10.30',
        username: 'admin',
        password: 'admin',
        client: client,
      );

      expect(result.ok, isTrue);
      expect(result.detail, contains('YDWG'));
    });

    test('probeYdwgLogin reports auth failure on 500', () async {
      final client = MockClient((request) async {
        return http.Response('Failed to authenticate', 500);
      });
      const service = PredictWindDatahubService();

      final result = await service.probeYdwgLogin(
        baseUrl: 'http://192.168.10.30',
        username: 'admin',
        password: 'wrong',
        client: client,
      );

      expect(result.ok, isFalse);
      expect(result.detail!.toLowerCase(), contains('sign in'));
    });

    test('default YDWG credentials fall back to factory admin', () {
      expect(PredictWindDatahubService.defaultYdwgUsername, 'admin');
      expect(PredictWindDatahubService.defaultYdwgPassword, 'admin');
      expect(
        PredictWindDatahubService.defaultYdwgUsernameResolved,
        isNotEmpty,
      );
    });
  });
}
