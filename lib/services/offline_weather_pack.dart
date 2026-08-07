import 'grib_download_service.dart' show GribBBox;

/// #291 — offline weather pack: what was downloaded in the marina for use mid-passage.
///
/// **Pack contents (v1):**
/// - One or more GRIB files on disk (wind GFS and/or wave GFS Wave)
/// - Metadata: bbox, source kind, download time, TTL
///
/// **TTL:** default 5 days from download (GFS skill decays; user can refresh
/// when online). Expired entries stay listed but [isFresh] is false so UI can
/// warn without deleting mid-passage.
///
/// **UI:** GRIB request screen downloads files; pack is the durable inventory
/// of those paths + metadata (no separate cloud service).
class OfflineWeatherPackEntry {
  final String path;
  /// `wind` | `wave` | `other`
  final String kind;
  final DateTime downloadedAt;
  final DateTime expiresAt;
  final double? minLat;
  final double? maxLat;
  final double? minLon;
  final double? maxLon;
  final String? label;

  const OfflineWeatherPackEntry({
    required this.path,
    required this.kind,
    required this.downloadedAt,
    required this.expiresAt,
    this.minLat,
    this.maxLat,
    this.minLon,
    this.maxLon,
    this.label,
  });

  Map<String, dynamic> toJson() => {
        'path': path,
        'kind': kind,
        'downloadedAt': downloadedAt.toUtc().toIso8601String(),
        'expiresAt': expiresAt.toUtc().toIso8601String(),
        'minLat': minLat,
        'maxLat': maxLat,
        'minLon': minLon,
        'maxLon': maxLon,
        'label': label,
      };

  factory OfflineWeatherPackEntry.fromJson(Map<String, dynamic> j) {
    return OfflineWeatherPackEntry(
      path: j['path'] as String? ?? '',
      kind: j['kind'] as String? ?? 'other',
      downloadedAt: DateTime.tryParse(j['downloadedAt'] as String? ?? '')
              ?.toUtc() ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      expiresAt:
          DateTime.tryParse(j['expiresAt'] as String? ?? '')?.toUtc() ??
              DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      minLat: (j['minLat'] as num?)?.toDouble(),
      maxLat: (j['maxLat'] as num?)?.toDouble(),
      minLon: (j['minLon'] as num?)?.toDouble(),
      maxLon: (j['maxLon'] as num?)?.toDouble(),
      label: j['label'] as String?,
    );
  }
}

/// Pure helpers for pack TTL / construction (no I/O).
class OfflineWeatherPack {
  OfflineWeatherPack._();

  /// Default freshness window for free GFS / wave downloads.
  static const Duration defaultTtl = Duration(days: 5);

  static bool isFresh(OfflineWeatherPackEntry e, [DateTime? now]) {
    final at = (now ?? DateTime.now()).toUtc();
    return !at.isAfter(e.expiresAt.toUtc());
  }

  static List<OfflineWeatherPackEntry> freshOnly(
    Iterable<OfflineWeatherPackEntry> entries, [
    DateTime? now,
  ]) =>
      entries.where((e) => isFresh(e, now)).toList();

  /// Build a pack entry after a successful download.
  static OfflineWeatherPackEntry fromDownload({
    required String path,
    required String kind,
    GribBBox? box,
    DateTime? downloadedAt,
    Duration ttl = defaultTtl,
    String? label,
  }) {
    final at = (downloadedAt ?? DateTime.now()).toUtc();
    final b = box?.normalized();
    return OfflineWeatherPackEntry(
      path: path,
      kind: kind,
      downloadedAt: at,
      expiresAt: at.add(ttl),
      minLat: b?.latMin,
      maxLat: b?.latMax,
      minLon: b?.lonMin,
      maxLon: b?.lonMax,
      label: label,
    );
  }
}
