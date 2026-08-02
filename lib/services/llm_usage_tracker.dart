import 'package:shared_preferences/shared_preferences.dart';

/// Token usage the provider itself reported for one completion (#15).
class LlmUsage {
  final int promptTokens;
  final int completionTokens;
  final int totalTokens;
  const LlmUsage({
    required this.promptTokens,
    required this.completionTokens,
    required this.totalTokens,
  });
}

/// Published list-price estimate per 1K tokens, USD. Approximate — actual
/// billing is between the user and their provider, this app never sees it.
class LlmModelPricing {
  final double inputPer1kUsd;
  final double outputPer1kUsd;
  const LlmModelPricing({
    required this.inputPer1kUsd,
    required this.outputPer1kUsd,
  });
}

/// Rough published list pricing (2026-08) for the models `LlmProvider` uses
/// by default. Deliberately approximate — never presented as exact billing.
const Map<String, LlmModelPricing> llmModelPricing = {
  'gpt-4o-mini': LlmModelPricing(inputPer1kUsd: 0.00015, outputPer1kUsd: 0.0006),
  'grok-3-mini': LlmModelPricing(inputPer1kUsd: 0.0003, outputPer1kUsd: 0.0005),
};

class LlmMonthlyUsage {
  final int totalTokens;
  final double estimatedCostUsd;
  const LlmMonthlyUsage({
    required this.totalTokens,
    required this.estimatedCostUsd,
  });
  static const zero = LlmMonthlyUsage(totalTokens: 0, estimatedCostUsd: 0);
}

/// #15: local, informational-only usage tracking — this app never meters or
/// bills the user's own BYOK provider account, but showing roughly how much
/// they've used (from the provider's own reported token counts) helps them
/// keep an eye on their own spend. Resets automatically each calendar month.
/// Per-device only: a shared boat key used from multiple crew devices only
/// reflects *this* device's usage, not the whole crew's — there's no sync
/// for this counter, by design (it's a courtesy estimate, not a ledger).
class LlmUsageTracker {
  static const _tokensKeyPrefix = 'llm_usage_tokens_';
  static const _costKeyPrefix = 'llm_usage_cost_';

  // Each calendar month gets its own key — a new month simply reads back 0
  // (SharedPreferences default) with no explicit reset step needed. Old
  // months' keys are left behind (cheap, bounded by how long the app is
  // installed); only the current month's key is ever read.
  String _currentMonthKey() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}';
  }

  double _estimateCost(LlmUsage usage, String modelId) {
    final pricing = llmModelPricing[modelId];
    if (pricing == null) return 0;
    return (usage.promptTokens / 1000 * pricing.inputPer1kUsd) +
        (usage.completionTokens / 1000 * pricing.outputPer1kUsd);
  }

  Future<void> record({
    required LlmUsage usage,
    required String modelId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final monthKey = _currentMonthKey();
    final tokens =
        (prefs.getInt('$_tokensKeyPrefix$monthKey') ?? 0) + usage.totalTokens;
    final cost = (prefs.getDouble('$_costKeyPrefix$monthKey') ?? 0) +
        _estimateCost(usage, modelId);
    await prefs.setInt('$_tokensKeyPrefix$monthKey', tokens);
    await prefs.setDouble('$_costKeyPrefix$monthKey', cost);
  }

  Future<LlmMonthlyUsage> currentMonth() async {
    final prefs = await SharedPreferences.getInstance();
    final monthKey = _currentMonthKey();
    return LlmMonthlyUsage(
      totalTokens: prefs.getInt('$_tokensKeyPrefix$monthKey') ?? 0,
      estimatedCostUsd: prefs.getDouble('$_costKeyPrefix$monthKey') ?? 0,
    );
  }
}
