import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sisu_mate/services/llm_usage_tracker.dart';

/// #15: local, informational-only token/cost tracking.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('currentMonth starts at zero with nothing recorded', () async {
    final usage = await LlmUsageTracker().currentMonth();
    expect(usage.totalTokens, 0);
    expect(usage.estimatedCostUsd, 0);
  });

  test('record accumulates tokens and an estimated cost for a known model',
      () async {
    final tracker = LlmUsageTracker();
    await tracker.record(
      usage: const LlmUsage(
          promptTokens: 100, completionTokens: 50, totalTokens: 150),
      modelId: 'gpt-4o-mini',
    );

    final usage = await tracker.currentMonth();
    expect(usage.totalTokens, 150);
    expect(usage.estimatedCostUsd, greaterThan(0));
  });

  test('repeated record calls accumulate rather than overwrite', () async {
    final tracker = LlmUsageTracker();
    await tracker.record(
      usage: const LlmUsage(
          promptTokens: 100, completionTokens: 50, totalTokens: 150),
      modelId: 'gpt-4o-mini',
    );
    await tracker.record(
      usage: const LlmUsage(
          promptTokens: 200, completionTokens: 100, totalTokens: 300),
      modelId: 'gpt-4o-mini',
    );

    final usage = await tracker.currentMonth();
    expect(usage.totalTokens, 450);
  });

  test('an unknown model still tracks tokens but estimates zero cost',
      () async {
    final tracker = LlmUsageTracker();
    await tracker.record(
      usage: const LlmUsage(
          promptTokens: 100, completionTokens: 50, totalTokens: 150),
      modelId: 'some-future-model',
    );

    final usage = await tracker.currentMonth();
    expect(usage.totalTokens, 150);
    expect(usage.estimatedCostUsd, 0);
  });
}
