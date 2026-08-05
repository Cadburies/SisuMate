/// #274 — one under-sail instrument snapshot used for polar learning.
/// Local-only (high volume; not crew-synced).
class SailingPolarSample {
  int id = 0;
  String boatSupabaseId = '';
  DateTime observedAt = DateTime.now().toUtc();

  /// Boat speed over ground (kn) — primary speed for polar targets.
  double sogKt = 0;

  /// Course over ground (°) — with [twdDeg] yields TWA.
  double? cogDeg;

  /// True wind speed (kn).
  double twsKt = 0;

  /// True wind direction (°) true north.
  double? twdDeg;

  /// Absolute true wind angle 0–180° (computed at capture).
  double twaDeg = 0;

  double? awsKt;
  double? awaDeg;
  double? depthMeters;

  /// Engine shaft RPM when present on NMEA. Null = not reported.
  double? enginePortRpm;
  double? engineStbdRpm;

  String sourceLabel = '';

  /// True after this sample contributed to a polar improve pass.
  bool usedInPolarBuild = false;
}
