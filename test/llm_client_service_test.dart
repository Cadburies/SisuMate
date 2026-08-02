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
}
