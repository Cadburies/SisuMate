import 'dart:async';
import 'dart:convert';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:http/http.dart' as http;

import '../models/models.dart';
import 'llm_usage_tracker.dart';

/// Which provider a boat's bring-your-own key targets (#203).
///
/// #223: [supportsGroundedSearch]/[groundedSearchEndpoint] — provider-side
/// live web/X search (current data, not just training-cutoff knowledge) is
/// a genuinely different API shape per provider, not a flag on the same
/// endpoint. Confirmed 2026-08-02: xAI's web_search/x_search tools live on
/// `/v1/responses` (input/output items), not `/v1/chat/completions`
/// (messages/choices) that [endpoint] points to. OpenAI has an equivalent
/// only on its own Responses API — genuinely unimplemented here, not just
/// unset by omission — so `openai.supportsGroundedSearch` stays false until
/// a future issue adds that separate integration; never assume parity.
enum LlmProvider {
  openai('openai', 'OpenAI', 'https://api.openai.com/v1/chat/completions',
      'gpt-4o-mini',
      supportsGroundedSearch: false, groundedSearchEndpoint: null),
  xai('xai', 'xAI (Grok)', 'https://api.x.ai/v1/chat/completions',
      'grok-3-mini',
      supportsGroundedSearch: true,
      groundedSearchEndpoint: 'https://api.x.ai/v1/responses');

  const LlmProvider(
    this.id,
    this.label,
    this.endpoint,
    this.defaultModel, {
    required this.supportsGroundedSearch,
    required this.groundedSearchEndpoint,
  });

  final String id;
  final String label;
  final String endpoint;
  final String defaultModel;
  final bool supportsGroundedSearch;
  final String? groundedSearchEndpoint;

  static LlmProvider? fromId(String? id) =>
      LlmProvider.values.where((p) => p.id == id).firstOrNull;
}

/// A source xAI's web_search/x_search tools cited while answering (#223).
class LlmCitation {
  final String url;
  final String? title;
  const LlmCitation({required this.url, this.title});
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

  /// #223: caller asked for grounded (live web/X) search but the boat's
  /// configured provider doesn't support it. Deliberately never falls back
  /// to a plain, ungrounded completion for a grounded-only call — a feature
  /// that specifically needs current data must not silently answer from
  /// stale training data instead.
  groundedSearchUnsupported,
}

class LlmResult {
  final LlmResultStatus status;
  final String? text;
  final String? errorMessage;
  final List<LlmCitation> citations;

  const LlmResult._(this.status,
      {this.text, this.errorMessage, this.citations = const []});

  const LlmResult.success(String text, {List<LlmCitation> citations = const []})
      : this._(LlmResultStatus.success, text: text, citations: citations);
  LlmResult.groundedSearchUnsupported(String providerLabel)
      : this._(LlmResultStatus.groundedSearchUnsupported,
            errorMessage: '$providerLabel doesn\'t support live web/X '
                'search — switch to a provider that does (xAI/Grok) in '
                'Settings to use this feature.');
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
    LlmUsageTracker? usageTracker,
    this.cacheTtl = const Duration(minutes: 10),
    this.maxCacheEntries = 50,
  })  : _http = httpClient ?? http.Client(),
        _connectivity = connectivity ?? Connectivity(),
        _usageTracker = usageTracker ?? LlmUsageTracker();

  final http.Client _http;
  final Connectivity _connectivity;
  final LlmUsageTracker _usageTracker;
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

      // #15: the provider's own reported token counts — informational-only
      // local tracking, never enforced/billed by this app.
      final usageJson = decoded['usage'] as Map<String, dynamic>?;
      if (usageJson != null) {
        final promptTokens = usageJson['prompt_tokens'] as int? ?? 0;
        final completionTokens = usageJson['completion_tokens'] as int? ?? 0;
        final totalTokens =
            usageJson['total_tokens'] as int? ?? promptTokens + completionTokens;
        unawaited(_usageTracker.record(
          usage: LlmUsage(
            promptTokens: promptTokens,
            completionTokens: completionTokens,
            totalTokens: totalTokens,
          ),
          modelId: provider.defaultModel,
        ));
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

  /// #223: like [complete] but asks the provider to ground its answer in
  /// live web/X search results — current data (visa rules, active unrest,
  /// disease alerts, regional crime reports) a plain completion can only
  /// guess about from its training cutoff. Only providers with
  /// [LlmProvider.supportsGroundedSearch] can serve this; every other
  /// provider gets [LlmResultStatus.groundedSearchUnsupported] — never a
  /// silent fallback to an ungrounded answer, since that would reintroduce
  /// exactly the staleness risk this method exists to avoid.
  ///
  /// Hits a different endpoint/request shape than [complete]: xAI's
  /// `/v1/responses` takes an `input` item list and returns an
  /// `output`/`output_text` shape, not `/v1/chat/completions`'s
  /// `messages`/`choices`. [LlmResult.citations] carries the sources the
  /// provider cited, parsed defensively — the exact response schema isn't
  /// fully published as of 2026-08; verify against
  /// https://docs.x.ai/docs/guides/live-search if provider behavior seems
  /// off, don't assume the parsing below is exhaustive.
  Future<LlmResult> completeWithSearch({
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
    if (!provider.supportsGroundedSearch ||
        provider.groundedSearchEndpoint == null) {
      return LlmResult.groundedSearchUnsupported(provider.label);
    }

    final cacheKey =
        'grounded|${_cacheKey(boat!, provider, systemPrompt, prompt)}';
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
        Uri.parse(provider.groundedSearchEndpoint!),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $key',
        },
        body: jsonEncode({
          'model': provider.defaultModel,
          'input': [
            if (systemPrompt != null)
              {'role': 'system', 'content': systemPrompt},
            {'role': 'user', 'content': prompt},
          ],
          'tools': [
            {'type': 'web_search'},
            {'type': 'x_search'},
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
      final content = _extractOutputText(decoded);
      if (content == null || content.isEmpty) {
        return const LlmResult.error('Provider returned no completion text');
      }
      final citations = _extractCitations(decoded);

      // #15: informational-only local tracking, plus #223's flat estimate
      // for the search-tool invocation cost xAI bills separately from
      // tokens (not exposed as its own response field as of 2026-08 — see
      // xaiGroundedSearchToolCostUsd's doc comment).
      final usageJson = decoded['usage'] as Map<String, dynamic>?;
      if (usageJson != null) {
        final promptTokens = usageJson['input_tokens'] as int? ??
            usageJson['prompt_tokens'] as int? ??
            0;
        final completionTokens = usageJson['output_tokens'] as int? ??
            usageJson['completion_tokens'] as int? ??
            0;
        final totalTokens = usageJson['total_tokens'] as int? ??
            promptTokens + completionTokens;
        unawaited(_usageTracker.record(
          usage: LlmUsage(
            promptTokens: promptTokens,
            completionTokens: completionTokens,
            totalTokens: totalTokens,
          ),
          modelId: provider.defaultModel,
          extraCostUsd: xaiGroundedSearchToolCostUsd,
        ));
      }

      final result = LlmResult.success(content, citations: citations);
      _cacheResult(cacheKey, result);
      return result;
    } on http.ClientException {
      return const LlmResult.offline();
    } catch (e) {
      return LlmResult.error(e.toString());
    }
  }

  /// Best-effort text extraction across the response shapes xAI's Responses
  /// API has been documented to use — a top-level `output_text`
  /// convenience field, or walking `output[].content[]` for text items
  /// (the OpenAI-style Responses API shape xAI's was modeled on).
  String? _extractOutputText(Map<String, dynamic> decoded) {
    final direct = decoded['output_text'] as String?;
    if (direct != null && direct.isNotEmpty) return direct;

    final output = decoded['output'] as List?;
    if (output == null) return null;
    final buffer = StringBuffer();
    for (final item in output) {
      if (item is! Map<String, dynamic> || item['type'] != 'message') {
        continue;
      }
      final content = item['content'] as List?;
      if (content == null) continue;
      for (final c in content) {
        if (c is! Map<String, dynamic>) continue;
        final text = c['text'] as String?;
        if (text != null) buffer.write(text);
      }
    }
    return buffer.isEmpty ? null : buffer.toString();
  }

  /// Citations may arrive as a flat list of URL strings or as objects with
  /// `url`/`title` — defensive either way since the exact schema isn't
  /// fully published (see [completeWithSearch]'s doc comment).
  List<LlmCitation> _extractCitations(Map<String, dynamic> decoded) {
    final raw = decoded['citations'] as List?;
    if (raw == null) return const [];
    final result = <LlmCitation>[];
    for (final item in raw) {
      if (item is String && item.isNotEmpty) {
        result.add(LlmCitation(url: item));
      } else if (item is Map<String, dynamic>) {
        final url = item['url'] as String?;
        if (url != null && url.isNotEmpty) {
          result.add(LlmCitation(url: url, title: item['title'] as String?));
        }
      }
    }
    return result;
  }
}
