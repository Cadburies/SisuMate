import 'dart:convert';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:sisu_mate/models/models.dart';
import 'package:sisu_mate/services/llm_client_service.dart';

/// Fake so tests control connectivity without a real platform channel.
class _FakeConnectivity implements Connectivity {
  final List<ConnectivityResult> result;
  _FakeConnectivity(this.result);

  @override
  Future<List<ConnectivityResult>> checkConnectivity() async => result;

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  Boat boatWith({String? key, String? provider}) => Boat()
    ..supabaseId = 'boat_1'
    ..llmApiKey = key
    ..llmApiKeyProvider = provider;

  test('no key configured returns noKeyConfigured without any network call',
      () async {
    var called = false;
    final service = LlmClientService(
      httpClient: MockClient((_) async {
        called = true;
        return http.Response('{}', 200);
      }),
      connectivity: _FakeConnectivity([ConnectivityResult.wifi]),
    );

    final result = await service.complete(boat: null, prompt: 'hello');

    expect(result.status, LlmResultStatus.noKeyConfigured);
    expect(called, isFalse);
  });

  test('offline returns offline without any network call', () async {
    var called = false;
    final service = LlmClientService(
      httpClient: MockClient((_) async {
        called = true;
        return http.Response('{}', 200);
      }),
      connectivity: _FakeConnectivity([ConnectivityResult.none]),
    );

    final result = await service.complete(
      boat: boatWith(key: 'sk-test', provider: 'openai'),
      prompt: 'hello',
    );

    expect(result.status, LlmResultStatus.offline);
    expect(called, isFalse);
  });

  test('200 with valid completion body returns success with the text',
      () async {
    final service = LlmClientService(
      httpClient: MockClient((request) async {
        expect(request.headers['Authorization'], 'Bearer sk-test');
        return http.Response(
          jsonEncode({
            'choices': [
              {
                'message': {'content': 'a sailor answer'}
              }
            ]
          }),
          200,
        );
      }),
      connectivity: _FakeConnectivity([ConnectivityResult.wifi]),
    );

    final result = await service.complete(
      boat: boatWith(key: 'sk-test', provider: 'openai'),
      prompt: 'hello',
    );

    expect(result.status, LlmResultStatus.success);
    expect(result.text, 'a sailor answer');
  });

  test('401 returns invalidKey', () async {
    final service = LlmClientService(
      httpClient: MockClient((_) async => http.Response('{}', 401)),
      connectivity: _FakeConnectivity([ConnectivityResult.wifi]),
    );

    final result = await service.complete(
      boat: boatWith(key: 'sk-bad', provider: 'openai'),
      prompt: 'hello',
    );

    expect(result.status, LlmResultStatus.invalidKey);
  });

  test('429 returns quotaExceeded', () async {
    final service = LlmClientService(
      httpClient: MockClient((_) async => http.Response('{}', 429)),
      connectivity: _FakeConnectivity([ConnectivityResult.wifi]),
    );

    final result = await service.complete(
      boat: boatWith(key: 'sk-test', provider: 'xai'),
      prompt: 'hello',
    );

    expect(result.status, LlmResultStatus.quotaExceeded);
  });

  test('unexpected status returns error, not a crash', () async {
    final service = LlmClientService(
      httpClient: MockClient((_) async => http.Response('server error', 500)),
      connectivity: _FakeConnectivity([ConnectivityResult.wifi]),
    );

    final result = await service.complete(
      boat: boatWith(key: 'sk-test', provider: 'openai'),
      prompt: 'hello',
    );

    expect(result.status, LlmResultStatus.error);
  });

  test('xai provider sends the request to the xAI endpoint', () async {
    late Uri calledUri;
    final service = LlmClientService(
      httpClient: MockClient((request) async {
        calledUri = request.url;
        return http.Response(
          jsonEncode({
            'choices': [
              {
                'message': {'content': 'ok'}
              }
            ]
          }),
          200,
        );
      }),
      connectivity: _FakeConnectivity([ConnectivityResult.wifi]),
    );

    await service.complete(
      boat: boatWith(key: 'sk-test', provider: 'xai'),
      prompt: 'hello',
    );

    expect(calledUri.host, 'api.x.ai');
  });

  group('#17 cost controls (caching)', () {
    LlmClientService serviceCountingCalls(
      int Function() incrementAndGet, {
      Duration cacheTtl = const Duration(minutes: 10),
    }) {
      return LlmClientService(
        httpClient: MockClient((_) async {
          incrementAndGet();
          return http.Response(
            jsonEncode({
              'choices': [
                {
                  'message': {'content': 'cached answer'}
                }
              ]
            }),
            200,
          );
        }),
        connectivity: _FakeConnectivity([ConnectivityResult.wifi]),
        cacheTtl: cacheTtl,
      );
    }

    test('an identical second query is served from cache, not the network',
        () async {
      var calls = 0;
      final service = serviceCountingCalls(() => ++calls);
      final boat = boatWith(key: 'sk-test', provider: 'openai');

      final first = await service.complete(boat: boat, prompt: 'hello');
      final second = await service.complete(boat: boat, prompt: 'hello');

      expect(calls, 1);
      expect(second.text, first.text);
      expect(second.status, LlmResultStatus.success);
    });

    test('a different prompt is not served from another prompt\'s cache entry',
        () async {
      var calls = 0;
      final service = serviceCountingCalls(() => ++calls);
      final boat = boatWith(key: 'sk-test', provider: 'openai');

      await service.complete(boat: boat, prompt: 'hello');
      await service.complete(boat: boat, prompt: 'goodbye');

      expect(calls, 2);
    });

    test('useCache: false always forces a fresh network call', () async {
      var calls = 0;
      final service = serviceCountingCalls(() => ++calls);
      final boat = boatWith(key: 'sk-test', provider: 'openai');

      await service.complete(boat: boat, prompt: 'hello');
      await service.complete(boat: boat, prompt: 'hello', useCache: false);

      expect(calls, 2);
    });

    test('an expired cache entry triggers a fresh network call', () async {
      var calls = 0;
      final service = serviceCountingCalls(() => ++calls,
          cacheTtl: const Duration(milliseconds: 1));
      final boat = boatWith(key: 'sk-test', provider: 'openai');

      await service.complete(boat: boat, prompt: 'hello');
      await Future<void>.delayed(const Duration(milliseconds: 10));
      await service.complete(boat: boat, prompt: 'hello');

      expect(calls, 2);
    });

    test('non-success results (e.g. errors) are never cached', () async {
      var calls = 0;
      final service = LlmClientService(
        httpClient: MockClient((_) async {
          calls++;
          return http.Response('server error', 500);
        }),
        connectivity: _FakeConnectivity([ConnectivityResult.wifi]),
      );
      final boat = boatWith(key: 'sk-test', provider: 'openai');

      await service.complete(boat: boat, prompt: 'hello');
      await service.complete(boat: boat, prompt: 'hello');

      expect(calls, 2,
          reason: 'an error result must never be served from cache — it '
              'would permanently mask a transient failure');
    });

    test('clearCache forces the next identical query back to the network',
        () async {
      var calls = 0;
      final service = serviceCountingCalls(() => ++calls);
      final boat = boatWith(key: 'sk-test', provider: 'openai');

      await service.complete(boat: boat, prompt: 'hello');
      service.clearCache();
      await service.complete(boat: boat, prompt: 'hello');

      expect(calls, 2);
    });
  });
}
