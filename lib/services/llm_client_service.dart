import 'dart:convert';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:http/http.dart' as http;

import '../models/models.dart';

/// Which provider a boat's bring-your-own key targets (#203).
enum LlmProvider {
  openai('openai', 'OpenAI', 'https://api.openai.com/v1/chat/completions',
      'gpt-4o-mini'),
  xai('xai', 'xAI (Grok)', 'https://api.x.ai/v1/chat/completions',
      'grok-3-mini');

  const LlmProvider(this.id, this.label, this.endpoint, this.defaultModel);

  final String id;
  final String label;
  final String endpoint;
  final String defaultModel;

  static LlmProvider? fromId(String? id) =>
      LlmProvider.values.where((p) => p.id == id).firstOrNull;
}

/// Outcome of an [LlmClientService.complete] call. Every LLM-powered feature
/// built on top of this (#15-#18, #20) should branch on [status] rather than
/// re-deriving provider-specific error parsing.
enum LlmResultStatus {
  success,

  /// No network attempt was made — never even reached the provider.
  offline,

  /// The active boat has no key configured for any provider.
  noKeyConfigured,

  /// Provider rejected the key itself (HTTP 401/403).
  invalidKey,

  /// Provider reports the account is out of tokens/credits (HTTP 429 or a
  /// billing/quota-shaped 402).
  quotaExceeded,

  /// Anything else — network hiccup, malformed response, unexpected status.
  error,
}

class LlmResult {
  final LlmResultStatus status;
  final String? text;
  final String? errorMessage;

  const LlmResult._(this.status, {this.text, this.errorMessage});

  const LlmResult.success(String text)
      : this._(LlmResultStatus.success, text: text);
  const LlmResult.offline()
      : this._(LlmResultStatus.offline,
            errorMessage: 'The app is offline — AI features need an internet '
                'connection.');
  const LlmResult.noKeyConfigured()
      : this._(LlmResultStatus.noKeyConfigured,
            errorMessage: 'No AI API key is configured for this boat yet — '
                'add one in Settings.');
  const LlmResult.invalidKey()
      : this._(LlmResultStatus.invalidKey,
            errorMessage: 'This AI API key was rejected by the provider — '
                'check it\'s correct and still active in Settings.');
  const LlmResult.quotaExceeded()
      : this._(LlmResultStatus.quotaExceeded,
            errorMessage: 'The AI provider account behind this key has no '
                'tokens/credits left.');
  const LlmResult.error(String message)
      : this._(LlmResultStatus.error, errorMessage: message);
}

class _CacheEntry {
  final LlmResult result;
  final DateTime expiresAt;
  _CacheEntry(this.result, this.expiresAt);
}

/// #203: the single entry point every LLM-powered feature calls. Bring-your-
/// own-key — reads the active boat's user-entered key and calls the chosen
/// provider directly from the device. This app never holds, proxies, meters,
/// or bills the key; it only surfaces what the provider itself reports back.
///
/// #17 cost controls: identical (boat, provider, prompt) queries within
/// [cacheTtl] are served from an in-memory cache instead of re-hitting the
/// provider — the cost being saved is the *user's own* token spend under
/// BYOK, not the app's, but nobody wants to burn tokens on a repeat query.
/// Only successful completions are cached; errors/offline/no-key are always
/// retried live. Model/prompt budget: [LlmProvider.defaultModel] is
/// deliberately the smallest/cheapest tier per provider (`gpt-4o-mini`,
/// `grok-3-mini`) — callers should keep [prompt]/[systemPrompt] short
/// (#16's payload builders already whitelist to small summaries, not bulk
/// data) since BYOK means the user pays per token, not this app.
class LlmClientService {
  LlmClientService({
    http.Client? httpClient,
    Connectivity? connectivity,
    this.cacheTtl = const Duration(minutes: 10),
    this.maxCacheEntries = 50,
  })  : _http = httpClient ?? http.Client(),
        _connectivity = connectivity ?? Connectivity();

  final http.Client _http;
  final Connectivity _connectivity;
  final Duration cacheTtl;
  final int maxCacheEntries;
  final Map<String, _CacheEntry> _cache = {};

  void clearCache() => _cache.clear();

  String _cacheKey(Boat boat, LlmProvider provider, String? systemPrompt,
          String prompt) =>
      '${boat.supabaseId}|${provider.id}|$systemPrompt|$prompt';

  void _cacheResult(String cacheKey, LlmResult result) {
    if (_cache.length >= maxCacheEntries && !_cache.containsKey(cacheKey)) {
      _cache.remove(_cache.keys.first); // oldest (insertion-ordered Map)
    }
    _cache[cacheKey] = _CacheEntry(result, DateTime.now().add(cacheTtl));
  }

  /// Sends [prompt] (already privacy-filtered by the caller — #16 owns
  /// building safe, summary-only payloads) through [boat]'s configured
  /// provider/key. Never throws; every outcome is a typed [LlmResult].
  /// [useCache] lets a caller force a fresh completion (e.g. a "regenerate"
  /// action) for an otherwise-identical query.
  Future<LlmResult> complete({
    required Boat? boat,
    required String prompt,
    String? systemPrompt,
    bool useCache = true,
  }) async {
    final provider = LlmProvider.fromId(boat?.llmApiKeyProvider);
    final key = boat?.llmApiKey;
    if (provider == null || key == null || key.trim().isEmpty) {
      return const LlmResult.noKeyConfigured();
    }

    final cacheKey = _cacheKey(boat!, provider, systemPrompt, prompt);
    if (useCache) {
      final cached = _cache[cacheKey];
      if (cached != null) {
        if (DateTime.now().isBefore(cached.expiresAt)) return cached.result;
        _cache.remove(cacheKey);
      }
    }

    final connectivityResult = await _connectivity.checkConnectivity();
    if (connectivityResult.every((r) => r == ConnectivityResult.none)) {
      return const LlmResult.offline();
    }

    try {
      final response = await _http.post(
        Uri.parse(provider.endpoint),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $key',
        },
        body: jsonEncode({
          'model': provider.defaultModel,
          'messages': [
            if (systemPrompt != null)
              {'role': 'system', 'content': systemPrompt},
            {'role': 'user', 'content': prompt},
          ],
        }),
      );

      if (response.statusCode == 401 || response.statusCode == 403) {
        return const LlmResult.invalidKey();
      }
      if (response.statusCode == 429 || response.statusCode == 402) {
        return const LlmResult.quotaExceeded();
      }
      if (response.statusCode != 200) {
        return LlmResult.error(
            'Provider returned HTTP ${response.statusCode}');
      }

      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      final choices = decoded['choices'] as List?;
      String? content;
      if (choices != null && choices.isNotEmpty) {
        final message =
            (choices.first as Map<String, dynamic>)['message']
                as Map<String, dynamic>?;
        content = message?['content'] as String?;
      }
      if (content == null || content.isEmpty) {
        return const LlmResult.error('Provider returned no completion text');
      }
      final result = LlmResult.success(content);
      _cacheResult(cacheKey, result);
      return result;
    } on http.ClientException {
      // Connectivity said online but the request itself couldn't reach the
      // provider (DNS blip, provider outage) — same user-facing outcome as
      // offline, not a bug to log.
      return const LlmResult.offline();
    } catch (e) {
      return LlmResult.error(e.toString());
    }
  }
}
