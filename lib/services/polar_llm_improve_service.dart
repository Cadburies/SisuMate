import 'dart:convert';

import '../data/repositories/sailing_polar_sample_repository.dart';
import '../domain/repositories/boat_repository.dart';
import '../models/models.dart';
import 'llm_client_service.dart';
import 'polar_bucket_aggregator.dart';

/// Outcome of a polar improve pass.
class PolarImproveResult {
  final bool ok;
  final String message;
  final List<PolarPoint>? polar;
  final bool usedLlm;

  const PolarImproveResult({
    required this.ok,
    required this.message,
    this.polar,
    this.usedLlm = false,
  });
}

/// #274 — heal/improve boat polar from collected under-sail samples.
///
/// 1. **Always offline-capable:** bucket samples → p90 → merge into polar
///    (max with existing).
/// 2. **When online + LLM key:** ask the configured model to smooth/fill
///    gaps; parse JSON array of {twaDeg,twsKt,boatSpeedKt}; re-merge
///    conservatively (max with measured merge).
class PolarLlmImproveService {
  PolarLlmImproveService({
    required SailingPolarSampleRepository samples,
    required BoatRepository boats,
    LlmClientService? llm,
  })  : _samples = samples,
        _boats = boats,
        _llm = llm ?? LlmClientService();

  final SailingPolarSampleRepository _samples;
  final BoatRepository _boats;
  final LlmClientService _llm;

  Future<PolarImproveResult> improve({
    required Boat boat,
    bool tryLlm = true,
  }) async {
    if (boat.supabaseId.isEmpty && boat.id == 0) {
      return const PolarImproveResult(
        ok: false,
        message: 'No boat selected.',
      );
    }

    final all = await _samples.listForBoat(boat.supabaseId, limit: 5000);
    if (all.isEmpty) {
      return const PolarImproveResult(
        ok: false,
        message:
            'No under-sail samples yet. Sail with instruments online and '
            'engines not showing revs — samples store offline automatically.',
      );
    }

    final buckets = PolarBucketAggregator.bucket(all);
    final usable =
        buckets.where((b) => b.sampleCount >= PolarBucketAggregator.minSamplesPerBucket);
    if (usable.isEmpty) {
      return PolarImproveResult(
        ok: false,
        message:
            'Have ${all.length} samples, but no TWA×TWS bucket has '
            '${PolarBucketAggregator.minSamplesPerBucket}+ points yet. '
            'Keep sailing in varied wind angles/speeds.',
      );
    }

    var merged = PolarBucketAggregator.mergeIntoPolar(
      existing: boat.polar,
      buckets: buckets,
    );

    var usedLlm = false;
    if (tryLlm) {
      final llmPolar = await _askLlm(
        boat: boat,
        current: merged,
        buckets: buckets.toList(),
        sampleCount: all.length,
      );
      if (llmPolar != null && llmPolar.isNotEmpty) {
        // Conservative: measured merge is the floor; LLM may add/fill.
        merged = PolarBucketAggregator.mergeIntoPolar(
          existing: llmPolar,
          buckets: buckets,
        );
        usedLlm = true;
      }
    }

    boat.polar = merged;
    boat.lastModified = DateTime.now().toUtc();
    await _boats.updateBoat(boat);

    await _samples.markUsed(all.map((s) => s.id));

    return PolarImproveResult(
      ok: true,
      polar: merged,
      usedLlm: usedLlm,
      message: usedLlm
          ? 'Polar updated from ${all.length} samples '
              '(${usable.length} buckets) + LLM refine → ${merged.length} points.'
          : 'Polar updated from ${all.length} samples '
              '(${usable.length} buckets, offline) → ${merged.length} points.',
    );
  }

  Future<List<PolarPoint>?> _askLlm({
    required Boat boat,
    required List<PolarPoint> current,
    required List<PolarBucket> buckets,
    required int sampleCount,
  }) async {
    final bucketSummary = [
      for (final b in buckets)
        if (b.sampleCount >= PolarBucketAggregator.minSamplesPerBucket)
          {
            'twaDeg': b.twaCentreDeg,
            'twsKt': b.twsCentreKt,
            'p90SogKt': b.representativeSogKt(p: 0.9),
            'n': b.sampleCount,
          },
    ];

    final system = '''
You are a sailing performance analyst. Given a boat's current polar table and
measured under-sail bucket statistics (TWA×TWS → p90 SOG), produce an improved
polar table as JSON only.

Rules:
- Output ONLY a JSON array of objects: {"twaDeg":number,"twsKt":number,"boatSpeedKt":number}
- twaDeg is absolute true wind angle 0..180 (port/starboard symmetric).
- Prefer measured p90 as a floor for buckets that have data; do not invent
  speeds much higher than measured without justification.
- Smooth obvious gaps; remove nonsense zeros; keep a usable sparse table
  (roughly 20–80 points is fine).
- No markdown fences, no commentary.
''';

    final prompt = '''
Boat: ${boat.name}
Samples collected: $sampleCount
Current polar (${current.length} points):
${jsonEncode(current.map((p) => p.toJson()).toList())}

Measured buckets (p90 SOG, n samples):
${jsonEncode(bucketSummary)}

Return improved polar JSON array.
''';

    final result = await _llm.complete(
      boat: boat,
      systemPrompt: system,
      prompt: prompt,
      useCache: false,
    );
    if (result.status != LlmResultStatus.success ||
        result.text == null ||
        result.text!.trim().isEmpty) {
      return null;
    }
    return _parsePolarJson(result.text!);
  }

  static List<PolarPoint>? _parsePolarJson(String raw) {
    var t = raw.trim();
    // Strip optional ```json fences.
    if (t.startsWith('```')) {
      t = t.replaceFirst(RegExp(r'^```(?:json)?\s*'), '');
      t = t.replaceFirst(RegExp(r'\s*```$'), '');
    }
    try {
      final decoded = jsonDecode(t);
      if (decoded is! List) return null;
      final out = <PolarPoint>[];
      for (final e in decoded) {
        if (e is! Map) continue;
        final m = Map<String, dynamic>.from(e);
        final twa = (m['twaDeg'] as num?)?.toDouble();
        final tws = (m['twsKt'] as num?)?.toDouble();
        final bs = (m['boatSpeedKt'] as num?)?.toDouble();
        if (twa == null || tws == null || bs == null) continue;
        if (!twa.isFinite || !tws.isFinite || !bs.isFinite) continue;
        if (bs <= 0 || tws < 0) continue;
        out.add(PolarPoint(twaDeg: twa, twsKt: tws, boatSpeedKt: bs));
      }
      return out.isEmpty ? null : out;
    } catch (_) {
      return null;
    }
  }
}
