import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/app_router.dart';
import '../../core/units.dart';
import '../../providers/passage_readiness_provider.dart' show cachedWeatherProvider;
import '../../providers/shopping_provider.dart' show activeBoatProvider;
import '../../services/llm_client_service.dart';
import '../../services/llm_payload_builder.dart';
import '../../services/weather_service.dart';

/// #219 (leftover from #18): synthesizes the already-fetched hourly wind +
/// marine wave forecast into a risk-focused go/no-go narrative — no new
/// network call, reads [cachedWeatherProvider] (BAI1's local-cache-only
/// weather read). Reached only via the passage planner's distinct AI action
/// (#208 separation).
class PassageWeatherBriefingDialog extends ConsumerStatefulWidget {
  const PassageWeatherBriefingDialog({super.key});

  @override
  ConsumerState<PassageWeatherBriefingDialog> createState() =>
      _PassageWeatherBriefingDialogState();
}

class _PassageWeatherBriefingDialogState
    extends ConsumerState<PassageWeatherBriefingDialog> {
  LlmResult? _result;
  bool _noCachedWeather = false;

  @override
  void initState() {
    super.initState();
    _generate();
  }

  Future<void> _generate() async {
    final bundle = await ref.read(cachedWeatherProvider.future);
    if (bundle == null) {
      if (mounted) setState(() => _noCachedWeather = true);
      return;
    }

    final boat = await ref.read(activeBoatProvider.future);
    // #230: cache-only read (no network call) — matches this dialog's
    // #219 discipline of never triggering a fetch of its own. A cache
    // miss (#229's ensemble fetch never ran, or it's stale/absent) just
    // means every hour's confidence stays null below.
    final ensemble = await WeatherService().loadEnsembleCache();
    String? confidenceForHour(DateTime t) {
      for (final e in ensemble?.hourly ?? const <EnsembleHourly>[]) {
        if (e.time.year == t.year &&
            e.time.month == t.month &&
            e.time.day == t.day &&
            e.time.hour == t.hour) {
          return e.confidence?.name;
        }
      }
      return null;
    }

    final payload = LlmPayloadBuilder.passageWeatherBriefing(
      placeName: bundle.placeName,
      hourlyWind: bundle.hourly.map((h) => (
            time: h.time,
            windKt: h.windMs == null ? null : h.windMs! / UnitConverter.msPerKnot,
            windDirDeg: h.windDirDeg,
            precipProb: h.precipProb,
            confidence: confidenceForHour(h.time),
          )),
      hourlyMarine: bundle.marine.map((m) => (
            time: m.time,
            waveHeightM: m.waveHeightM,
            waveDirDeg: m.waveDirDeg,
            wavePeriodS: m.wavePeriodS,
          )),
    );
    final result = await LlmClientService().complete(
      boat: boat,
      systemPrompt: 'You are a sailing passage-planning safety assistant. '
          'Given an hourly wind forecast and marine wave forecast window, '
          'write a short, risk-focused go/no-go briefing: call out any '
          'wind/wave/timing hazards you can infer (e.g. wind building '
          'against short wave periods, a window where conditions ease), '
          'and suggest safer departure timing if relevant. Some hours may '
          'carry a "confidence" value (high/medium/low) reflecting forecast '
          'model agreement — when present, let it shape your language '
          '(e.g. treat a low-confidence hour\'s numbers as a rough guide, '
          'not a plan); when absent, reason from the numbers alone as '
          'usual. 3-5 sentences, no preamble.',
      prompt: jsonEncode(payload),
    );
    if (mounted) setState(() => _result = result);
  }

  @override
  Widget build(BuildContext context) {
    final result = _result;
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.auto_awesome, color: Colors.deepPurple, size: 20),
          SizedBox(width: 8),
          Expanded(
            child: Text('AI: Weather safety briefing',
                overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: _noCachedWeather
            ? const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline, size: 18),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text('No cached weather yet — open Weather and '
                        'load a forecast for this area first.'),
                  ),
                ],
              )
            : result == null
                ? const SizedBox(
                    height: 80,
                    child: Center(child: CircularProgressIndicator()),
                  )
                : _ResultView(result: result),
      ),
      actions: [
        if (result?.status == LlmResultStatus.noKeyConfigured)
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.push(AppRoutes.settings);
            },
            child: const Text('Go to Settings'),
          ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }
}

class _ResultView extends StatelessWidget {
  final LlmResult result;
  const _ResultView({required this.result});

  @override
  Widget build(BuildContext context) {
    if (result.status != LlmResultStatus.success) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline,
              size: 18, color: Theme.of(context).colorScheme.error),
          const SizedBox(width: 8),
          Expanded(child: Text(result.errorMessage ?? 'Something went wrong.')),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(result.text ?? ''),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.info_outline,
                size: 16, color: Theme.of(context).colorScheme.secondary),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                'AI-generated guidance, not a substitute for checking '
                'official forecasts/NOTAMs before departure.',
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(fontStyle: FontStyle.italic),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
