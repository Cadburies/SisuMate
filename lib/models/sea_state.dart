/// #276/#280 — sea state for polar learning.
///
/// Two offline proxies feed the same buckets:
/// - **Instrument variance** (speed CV + TWA std) — [SeaStateEstimator]
/// - **Phone IMU** heave / proxy Hs with WMO-style bands — [ImuHeaveEstimator]
///
/// Not a calibrated buoy Douglas scale. Buckets keep polar targets honest:
/// smooth-sailing polars are not mixed with rough-sea samples the boat
/// cannot match.
enum SeaState {
  /// Smooth sailing — low instrument variance.
  calm,

  /// Some motion; between calm and rough.
  moderate,

  /// Rough seas — high speed/TWA variance; polar targets stay lower.
  rough,

  /// Not enough window data yet.
  unknown;

  String get wireValue => name;

  String get label => switch (this) {
        SeaState.calm => 'Smooth',
        SeaState.moderate => 'Moderate',
        SeaState.rough => 'Rough',
        SeaState.unknown => 'Unknown',
      };

  String get shortHint => switch (this) {
        SeaState.calm => 'Smooth sailing — target polar speeds',
        SeaState.moderate => 'Some chop — mid polars',
        SeaState.rough => 'Rough seas — lower achievable speeds',
        SeaState.unknown => 'Collecting instrument window…',
      };

  static SeaState fromWire(String? raw) {
    if (raw == null || raw.isEmpty) return SeaState.unknown;
    return SeaState.values.firstWhere(
      (e) => e.name == raw,
      orElse: () => SeaState.unknown,
    );
  }

  /// Stable order for charts / legends (skip unknown for curves).
  static const chartOrder = [SeaState.calm, SeaState.moderate, SeaState.rough];
}
