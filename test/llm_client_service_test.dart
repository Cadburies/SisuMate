import 'dart:convert';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sisu_mate/models/models.dart';
import 'package:sisu_mate/services/llm_client_service.dart';
import 'package:sisu_mate/services/llm_usage_tracker.dart';

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
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

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

  group('#15 usage tracking', () {
    test('a successful completion with a usage field records it locally',
        () async {
      final service = LlmClientService(
        httpClient: MockClient((_) async {
          return http.Response(
            jsonEncode({
              'choices': [
                {
                  'message': {'content': 'ok'}
                }
              ],
              'usage': {
                'prompt_tokens': 20,
                'completion_tokens': 10,
                'total_tokens': 30,
              },
            }),
            200,
          );
        }),
        connectivity: _FakeConnectivity([ConnectivityResult.wifi]),
      );

      await service.complete(
        boat: boatWith(key: 'sk-test', provider: 'openai'),
        prompt: 'hello',
      );
      // recording is fire-and-forget (unawaited) — give it a tick.
      await Future<void>.delayed(Duration.zero);

      final usage = await LlmUsageTracker().currentMonth();
      expect(usage.totalTokens, 30);
    });

    test('a successful completion with no usage field records nothing',
        () async {
      final service = LlmClientService(
        httpClient: MockClient((_) async {
          return http.Response(
            jsonEncode({
              'choices': [
                {
                  'message': {'content': 'ok'}
                }
              ],
            }),
            200,
          );
        }),
        connectivity: _FakeConnectivity([ConnectivityResult.wifi]),
      );

      await service.complete(
        boat: boatWith(key: 'sk-test', provider: 'openai'),
        prompt: 'hello',
      );
      await Future<void>.delayed(Duration.zero);

      final usage = await LlmUsageTracker().currentMonth();
      expect(usage.totalTokens, 0);
    });
  });

  group('#223 completeWithSearch (grounded web/X search)', () {
    test('a provider without supportsGroundedSearch is rejected without '
        'any network call', () async {
      var called = false;
      final service = LlmClientService(
        httpClient: MockClient((_) async {
          called = true;
          return http.Response('{}', 200);
        }),
        connectivity: _FakeConnectivity([ConnectivityResult.wifi]),
      );

      final result = await service.completeWithSearch(
        boat: boatWith(key: 'sk-test', provider: 'openai'),
        prompt: 'is it safe to sail to X?',
      );

      expect(result.status, LlmResultStatus.groundedSearchUnsupported);
      expect(result.errorMessage, contains('OpenAI'));
      expect(called, isFalse,
          reason: 'must never fall back to a plain, ungrounded completion');
    });

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

      final result =
          await service.completeWithSearch(boat: null, prompt: 'hello');

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

      final result = await service.completeWithSearch(
        boat: boatWith(key: 'sk-test', provider: 'xai'),
        prompt: 'hello',
      );

      expect(result.status, LlmResultStatus.offline);
      expect(called, isFalse);
    });

    test('sends the request to the xAI /v1/responses endpoint with '
        'web_search and x_search tools', () async {
      late Uri calledUri;
      late Map<String, dynamic> calledBody;
      final service = LlmClientService(
        httpClient: MockClient((request) async {
          calledUri = request.url;
          calledBody = jsonDecode(request.body) as Map<String, dynamic>;
          return http.Response(
            jsonEncode({'output_text': 'looks fine'}),
            200,
          );
        }),
        connectivity: _FakeConnectivity([ConnectivityResult.wifi]),
      );

      await service.completeWithSearch(
        boat: boatWith(key: 'sk-test', provider: 'xai'),
        prompt: 'hello',
      );

      expect(calledUri.toString(), 'https://api.x.ai/v1/responses');
      final tools = calledBody['tools'] as List;
      expect(tools, [
        {'type': 'web_search'},
        {'type': 'x_search'},
      ]);
      expect(calledBody['input'], [
        {'role': 'user', 'content': 'hello'}
      ]);
    });

    test('parses a top-level output_text response', () async {
      final service = LlmClientService(
        httpClient: MockClient((_) async => http.Response(
            jsonEncode({'output_text': 'a grounded answer'}), 200)),
        connectivity: _FakeConnectivity([ConnectivityResult.wifi]),
      );

      final result = await service.completeWithSearch(
        boat: boatWith(key: 'sk-test', provider: 'xai'),
        prompt: 'hello',
      );

      expect(result.status, LlmResultStatus.success);
      expect(result.text, 'a grounded answer');
    });

    test('falls back to walking output[].content[] when output_text is '
        'absent', () async {
      final service = LlmClientService(
        httpClient: MockClient((_) async => http.Response(
              jsonEncode({
                'output': [
                  {
                    'type': 'message',
                    'content': [
                      {'type': 'output_text', 'text': 'walked answer'},
                    ],
                  },
                ],
              }),
              200,
            )),
        connectivity: _FakeConnectivity([ConnectivityResult.wifi]),
      );

      final result = await service.completeWithSearch(
        boat: boatWith(key: 'sk-test', provider: 'xai'),
        prompt: 'hello',
      );

      expect(result.status, LlmResultStatus.success);
      expect(result.text, 'walked answer');
    });

    test('parses citations as objects with url/title', () async {
      final service = LlmClientService(
        httpClient: MockClient((_) async => http.Response(
              jsonEncode({
                'output_text': 'answer',
                'citations': [
                  {'url': 'https://example.com/a', 'title': 'Source A'},
                  {'url': 'https://example.com/b'},
                ],
              }),
              200,
            )),
        connectivity: _FakeConnectivity([ConnectivityResult.wifi]),
      );

      final result = await service.completeWithSearch(
        boat: boatWith(key: 'sk-test', provider: 'xai'),
        prompt: 'hello',
      );

      expect(result.citations, hasLength(2));
      expect(result.citations[0].url, 'https://example.com/a');
      expect(result.citations[0].title, 'Source A');
      expect(result.citations[1].title, isNull);
    });

    test('parses citations as a flat list of URL strings', () async {
      final service = LlmClientService(
        httpClient: MockClient((_) async => http.Response(
              jsonEncode({
                'output_text': 'answer',
                'citations': ['https://example.com/a'],
              }),
              200,
            )),
        connectivity: _FakeConnectivity([ConnectivityResult.wifi]),
      );

      final result = await service.completeWithSearch(
        boat: boatWith(key: 'sk-test', provider: 'xai'),
        prompt: 'hello',
      );

      expect(result.citations.single.url, 'https://example.com/a');
    });

    test('no citations field parses to an empty list, not a crash', () async {
      final service = LlmClientService(
        httpClient: MockClient(
            (_) async => http.Response(jsonEncode({'output_text': 'ok'}), 200)),
        connectivity: _FakeConnectivity([ConnectivityResult.wifi]),
      );

      final result = await service.completeWithSearch(
        boat: boatWith(key: 'sk-test', provider: 'xai'),
        prompt: 'hello',
      );

      expect(result.citations, isEmpty);
    });

    test('401 returns invalidKey', () async {
      final service = LlmClientService(
        httpClient: MockClient((_) async => http.Response('{}', 401)),
        connectivity: _FakeConnectivity([ConnectivityResult.wifi]),
      );

      final result = await service.completeWithSearch(
        boat: boatWith(key: 'sk-bad', provider: 'xai'),
        prompt: 'hello',
      );

      expect(result.status, LlmResultStatus.invalidKey);
    });

    test('a grounded call records usage plus the extra tool-cost estimate',
        () async {
      final service = LlmClientService(
        httpClient: MockClient((_) async => http.Response(
              jsonEncode({
                'output_text': 'ok',
                'usage': {
                  'input_tokens': 50,
                  'output_tokens': 20,
                  'total_tokens': 70,
                },
              }),
              200,
            )),
        connectivity: _FakeConnectivity([ConnectivityResult.wifi]),
      );

      await service.completeWithSearch(
        boat: boatWith(key: 'sk-test', provider: 'xai'),
        prompt: 'hello',
      );
      await Future<void>.delayed(Duration.zero);

      final usage = await LlmUsageTracker().currentMonth();
      expect(usage.totalTokens, 70);
      expect(usage.estimatedCostUsd, greaterThan(xaiGroundedSearchToolCostUsd),
          reason: 'should include both token cost and the flat tool-cost '
              'estimate, not just one or the other');
    });

    test('grounded and plain completions for the same prompt cache '
        'separately', () async {
      var groundedCalls = 0;
      var plainCalls = 0;
      final service = LlmClientService(
        httpClient: MockClient((request) async {
          if (request.url.path.contains('responses')) {
            groundedCalls++;
            return http.Response(jsonEncode({'output_text': 'grounded'}), 200);
          }
          plainCalls++;
          return http.Response(
            jsonEncode({
              'choices': [
                {
                  'message': {'content': 'plain'}
                }
              ]
            }),
            200,
          );
        }),
        connectivity: _FakeConnectivity([ConnectivityResult.wifi]),
      );
      final boat = boatWith(key: 'sk-test', provider: 'xai');

      final grounded = await service.completeWithSearch(boat: boat, prompt: 'hello');
      final plain = await service.complete(boat: boat, prompt: 'hello');

      expect(grounded.text, 'grounded');
      expect(plain.text, 'plain');
      expect(groundedCalls, 1);
      expect(plainCalls, 1);
    });
  });
}
