import 'dart:convert';

import '../data/repositories/sailing_polar_sample_repository.dart';
import '../domain/repositories/boat_repository.dart';
import '../models/models.dart';
import '../models/sea_state.dart';
import 'llm_client_service.dart';
import 'polar_bucket_aggregator.dart';
import 'polar_local_improve.dart';

/// Outcome of a polar improve pass.
class PolarImproveResult {
  final bool ok;
  final String message;
  final List<PolarPoint>? polar;
  final Map<String, List<PolarPoint>>? polarBySeaState;
  final bool usedLlm;

  const PolarImproveResult({
    required this.ok,
    required this.message,
    this.polar,
    this.polarBySeaState,
    this.usedLlm = false,
  });
}

/// #274/#276 — heal/improve boat polar from collected under-sail samples.
///
/// 1. **Always offline-capable:** steady samples already filtered at
///    collection → outlier-clean buckets → p90 → per-sea-state merge →
///    optional spline smooth. Primary polar prefers calm targets.
/// 2. **When online + LLM key:** optional refine of the primary polar only;
///    re-merge conservatively (max with measured).
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
    bool applySpline = true,
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

    final local = PolarLocalImprove.improveOffline(
      existing: boat.polar,
      samples: all,
      applySpline: applySpline,
    );

    if (local.usableBucketCount == 0 && local.primaryPolar.isEmpty) {
      return PolarImproveResult(
        ok: false,
        message:
            'Have ${all.length} samples, but no TWA×TWS bucket has '
            '${PolarBucketAggregator.minSamplesPerBucket}+ clean points yet. '
            'Keep sailing in varied wind angles/speeds (and sea states).',
      );
    }

    var merged = local.primaryPolar;
    final bySea = Map<String, List<PolarPoint>>.from(local.polarBySeaState);

    var usedLlm = false;
    if (tryLlm) {
      final buckets = PolarLocalImprove.bucketClean(samples: all);
      final llmPolar = await _askLlm(
        boat: boat,
        current: merged,
        buckets: buckets,
        sampleCount: all.length,
      );
      if (llmPolar != null && llmPolar.isNotEmpty) {
        merged = PolarBucketAggregator.mergeIntoPolar(
          existing: llmPolar,
          buckets: buckets,
        );
        usedLlm = true;
      }
    }

    boat.polar = merged;
    boat.polarBySeaState = bySea;
    boat.lastModified = DateTime.now().toUtc();
    await _boats.updateBoat(boat);

    await _samples.markUsed(all.map((s) => s.id));

    final seaSummary = bySea.entries
        .map((e) => '${e.key}:${e.value.length}')
        .join(', ');

    return PolarImproveResult(
      ok: true,
      polar: merged,
      polarBySeaState: bySea,
      usedLlm: usedLlm,
      message: usedLlm
          ? 'Polar updated from ${all.length} samples '
              '(${local.usableBucketCount} buckets, sea states [$seaSummary]) '
              '+ LLM refine → ${merged.length} primary points.'
          : 'Polar updated from ${all.length} samples '
              '(${local.usableBucketCount} buckets offline, sea states '
              '[$seaSummary]) → ${merged.length} primary points.',
    );
  }

  /// #276 — clear one sea-state polar curve (and optionally its samples).
  ///
  /// Resetting **Smooth (calm)** also clears the primary routing polar when
  /// no calm curve remains. Moderate/rough resets leave the primary alone.
  Future<PolarImproveResult> resetSeaState({
    required Boat boat,
    required SeaState seaState,
    bool deleteSamples = false,
  }) async {
    if (seaState == SeaState.unknown) {
      return const PolarImproveResult(
        ok: false,
        message: 'Pick Smooth, Moderate, or Rough to reset.',
      );
    }
    final wire = seaState.wireValue;
    final remaining =
        removeSeaStatePolar(boat.polarBySeaState, wire);
    final primary = primaryPolarAfterSeaStateReset(
      remaining: remaining,
      previousPrimary: boat.polar,
      removedSeaWire: wire,
    );

    var deleted = 0;
    if (deleteSamples && boat.supabaseId.isNotEmpty) {
      deleted = await _samples.deleteForBoat(
        boat.supabaseId,
        seaState: wire,
      );
    }

    boat.polarBySeaState = remaining;
    boat.polar = primary;
    boat.lastModified = DateTime.now().toUtc();
    await _boats.updateBoat(boat);

    final sampleNote = deleteSamples
        ? ' Deleted $deleted ${seaState.label.toLowerCase()} sample'
            '${deleted == 1 ? '' : 's'}.'
        : ' Samples kept — Improve can rebuild this curve.';

    return PolarImproveResult(
      ok: true,
      polar: primary,
      polarBySeaState: remaining,
      message:
          'Reset ${seaState.label} polar (${remaining.length} sea-state '
          'curve${remaining.length == 1 ? '' : 's'} left).$sampleNote',
    );
  }

  /// Clear every sea-state curve + primary polar (optional all samples).
  Future<PolarImproveResult> resetAll({
    required Boat boat,
    bool deleteSamples = false,
  }) async {
    var deleted = 0;
    if (deleteSamples && boat.supabaseId.isNotEmpty) {
      deleted = await _samples.deleteForBoat(boat.supabaseId);
    }

    boat.polar = [];
    boat.polarBySeaState = {};
    boat.lastModified = DateTime.now().toUtc();
    await _boats.updateBoat(boat);

    final sampleNote = deleteSamples
        ? ' Deleted $deleted sample${deleted == 1 ? '' : 's'}.'
        : ' Samples kept — Improve can rebuild.';

    return PolarImproveResult(
      ok: true,
      polar: const [],
      polarBySeaState: const {},
      message: 'Reset all polar curves.$sampleNote',
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
