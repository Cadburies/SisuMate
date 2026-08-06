/// #274/#275 — one under-sail instrument snapshot used for polar learning.
///
/// **Anonymized on the wire** ([toSyncJson]): performance metrics only — no
/// track (lat/lon never stored), no engine RPM, no raw source host labels.
/// Full detail stays local for debugging; Supabase gets the thin payload.
class SailingPolarSample {
  SailingPolarSample();

  int id = 0;
  String supabaseId = '';
  String boatSupabaseId = '';
  DateTime observedAt = DateTime.now().toUtc();

  /// SOG (kn) when available — always recorded if present for analysis.
  double? sogKt;

  /// Speed through water (kn) when NMEA/Hub provides it.
  double? stwKt;

  /// Preferred boat speed for polar targets: STW if valid, else SOG.
  double boatSpeedKt = 0;

  /// `stw` or `sog` — which field [boatSpeedKt] came from.
  String speedSource = 'sog';

  /// Course over ground (°) — local only; not on wire.
  double? cogDeg;

  /// True wind speed (kn).
  double twsKt = 0;

  /// True wind direction (°) — local only; not on wire (TWA is enough).
  double? twdDeg;

  /// Absolute true wind angle 0–180° (computed at capture).
  double twaDeg = 0;

  double? awsKt;
  double? awaDeg;
  double? depthMeters;

  /// Engine shaft RPM when present on NMEA. Local only; not on wire.
  double? enginePortRpm;
  double? engineStbdRpm;

  String sourceLabel = '';

  /// #276 — calm | moderate | rough | unknown (instrument-variance proxy).
  String seaState = 'unknown';

  /// Local-only diagnostics from the rolling window (not on wire).
  double? speedCv;
  double? twaStdDeg;

  /// True after this sample contributed to a polar improve pass.
  bool usedInPolarBuild = false;

  bool isSynced = false;
  DateTime lastModified = DateTime.now().toUtc();

  /// Full local persistence (includes fields omitted from sync).
  Map<String, dynamic> toLocalJson() => {
        'supabaseId': supabaseId,
        'boatSupabaseId': boatSupabaseId,
        'observedAt': observedAt.toIso8601String(),
        'sogKt': sogKt,
        'stwKt': stwKt,
        'boatSpeedKt': boatSpeedKt,
        'speedSource': speedSource,
        'cogDeg': cogDeg,
        'twsKt': twsKt,
        'twdDeg': twdDeg,
        'twaDeg': twaDeg,
        'awsKt': awsKt,
        'awaDeg': awaDeg,
        'depthMeters': depthMeters,
        'enginePortRpm': enginePortRpm,
        'engineStbdRpm': engineStbdRpm,
        'sourceLabel': sourceLabel,
        'seaState': seaState,
        'speedCv': speedCv,
        'twaStdDeg': twaStdDeg,
        'usedInPolarBuild': usedInPolarBuild,
        'isSynced': isSynced,
        'lastModified': lastModified.toIso8601String(),
      };

  /// #275/#276 — anonymized wire payload (no track, no engines; seaState ok).
  Map<String, dynamic> toSyncJson() => {
        'supabaseId': supabaseId,
        'boatSupabaseId': boatSupabaseId,
        'observedAt': observedAt.toIso8601String(),
        'boatSpeedKt': boatSpeedKt,
        'speedSource': speedSource,
        'sogKt': sogKt,
        'stwKt': stwKt,
        'twaDeg': twaDeg,
        'twsKt': twsKt,
        'seaState': seaState,
        'isSynced': isSynced,
        'lastModified': lastModified.toIso8601String(),
      };

  factory SailingPolarSample.fromJson(Map<String, dynamic> j) {
    double? d(dynamic v) => v is num ? v.toDouble() : null;
    return SailingPolarSample()
      ..supabaseId = j['supabaseId'] as String? ?? ''
      ..boatSupabaseId = j['boatSupabaseId'] as String? ?? ''
      ..observedAt = DateTime.tryParse(j['observedAt'] as String? ?? '')
              ?.toUtc() ??
          DateTime.now().toUtc()
      ..sogKt = d(j['sogKt'])
      ..stwKt = d(j['stwKt'])
      ..boatSpeedKt = d(j['boatSpeedKt']) ?? d(j['sogKt']) ?? 0
      ..speedSource = j['speedSource'] as String? ?? 'sog'
      ..cogDeg = d(j['cogDeg'])
      ..twsKt = d(j['twsKt']) ?? 0
      ..twdDeg = d(j['twdDeg'])
      ..twaDeg = d(j['twaDeg']) ?? 0
      ..awsKt = d(j['awsKt'])
      ..awaDeg = d(j['awaDeg'])
      ..depthMeters = d(j['depthMeters'])
      ..enginePortRpm = d(j['enginePortRpm'])
      ..engineStbdRpm = d(j['engineStbdRpm'])
      ..sourceLabel = j['sourceLabel'] as String? ?? ''
      ..seaState = j['seaState'] as String? ?? 'unknown'
      ..speedCv = d(j['speedCv'])
      ..twaStdDeg = d(j['twaStdDeg'])
      ..usedInPolarBuild = j['usedInPolarBuild'] as bool? ?? false
      ..isSynced = j['isSynced'] as bool? ?? false
      ..lastModified = DateTime.tryParse(j['lastModified'] as String? ?? '')
              ?.toUtc() ??
          DateTime.now().toUtc();
  }
}
