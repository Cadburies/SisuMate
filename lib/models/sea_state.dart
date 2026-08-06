/// #276 — instrument-derived sea state for polar learning.
///
/// Not Douglas scale / buoy wave height. Fully offline proxy from short-term
/// variance of boat instruments (speed CV + TWA std). Rough water inflates
/// those; calm water keeps them low. Buckets keep polar targets honest:
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
