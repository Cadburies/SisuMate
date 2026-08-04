import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:sisu_mate/services/predictwind_datahub_service.dart';

/// #256 — PredictWind Datahub connectivity. `dart-defines.json`'s
/// PREDICTWIND_HUB_URL/PREDICTWIND_HUB_HTTP_URL aren't set in `flutter
/// test` runs (no --dart-define-from-file passed) — compile-time
/// `String.fromEnvironment` values can't be overridden at runtime, so the
/// classification branches are exercised via the `baseUrlOverride`
/// test-only constructor seam plus a `MockClient` standing in for the real
/// host, rather than the real dart-defines-driven URL.
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

  test(
      'a 403 with X-LuCI-Login-Required classifies as reachableAuthRequired '
      '(matches the real PW-Hub response, live-verified 2026-08-04)',
      () async {
    final client = MockClient((request) async {
      expect(request.url.toString(), 'https://fake-hub.test/cgi-bin/luci/');
      return http.Response('', 403,
          headers: {'x-luci-login-required': 'yes'});
    });
    const service =
        PredictWindDatahubService(baseUrlOverride: 'https://fake-hub.test');

    final status = await service.checkConnection(client: client);

    expect(status.state, PredictWindHubConnectionState.reachableAuthRequired);
  });

  test('a 200 response classifies as reachable', () async {
    final client = MockClient((request) async => http.Response('ok', 200));
    const service =
        PredictWindDatahubService(baseUrlOverride: 'https://fake-hub.test');

    final status = await service.checkConnection(client: client);

    expect(status.state, PredictWindHubConnectionState.reachable);
  });

  test('a thrown error (timeout/connection refused) classifies as unreachable',
      () async {
    final client = MockClient((request) async {
      throw Exception('connection refused');
    });
    const service =
        PredictWindDatahubService(baseUrlOverride: 'https://fake-hub.test');

    final status = await service.checkConnection(client: client);

    expect(status.state, PredictWindHubConnectionState.unreachable);
    expect(status.detail, contains('connection refused'));
  });

  test('an unexpected error status (not 403) classifies as unreachable',
      () async {
    final client = MockClient((request) async => http.Response('', 500));
    const service =
        PredictWindDatahubService(baseUrlOverride: 'https://fake-hub.test');

    final status = await service.checkConnection(client: client);

    expect(status.state, PredictWindHubConnectionState.unreachable);
    expect(status.detail, contains('500'));
  });

  test('fetchBoatData returns null — no confirmed data endpoint yet',
      () async {
    const service = PredictWindDatahubService();
    final data = await service.fetchBoatData();
    expect(data, isNull);
  });
}
