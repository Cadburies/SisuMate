import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import 'error_log_service.dart';
import 'grib_import_service.dart';

/// Bounding box for free GRIB subset downloads (signed degrees).
class GribBBox {
  final double latMin;
  final double latMax;
  final double lonMin;
  final double lonMax;

  const GribBBox({
    required this.latMin,
    required this.latMax,
    required this.lonMin,
    required this.lonMax,
  });

  /// Expand so north ≥ south and east ≥ west (handles antimeridian poorly —
  /// v1 assumes route does not cross ±180).
  GribBBox normalized() {
    final s = math.min(latMin, latMax);
    final n = math.max(latMin, latMax);
    final w = math.min(lonMin, lonMax);
    final e = math.max(lonMin, lonMax);
    return GribBBox(latMin: s, latMax: n, lonMin: w, lonMax: e);
  }

  GribBBox padded(double marginDeg) {
    final n = normalized();
    return GribBBox(
      latMin: (n.latMin - marginDeg).clamp(-90.0, 90.0),
      latMax: (n.latMax + marginDeg).clamp(-90.0, 90.0),
      lonMin: (n.lonMin - marginDeg).clamp(-180.0, 180.0),
      lonMax: (n.lonMax + marginDeg).clamp(-180.0, 180.0),
    );
  }

  /// Axis-aligned box covering [points], plus [marginDeg].
  static GribBBox fromPoints(
    Iterable<({double lat, double lon})> points, {
    double marginDeg = 1.0,
    double minHalfSpanDeg = 0.5,
  }) {
    final list = points.toList();
    if (list.isEmpty) {
      return const GribBBox(latMin: -1, latMax: 1, lonMin: -1, lonMax: 1)
          .padded(marginDeg);
    }
    var s = list.first.lat;
    var n = list.first.lat;
    var w = list.first.lon;
    var e = list.first.lon;
    for (final p in list.skip(1)) {
      s = math.min(s, p.lat);
      n = math.max(n, p.lat);
      w = math.min(w, p.lon);
      e = math.max(e, p.lon);
    }
    // Tiny / single-point routes still need a usable filter box.
    if (n - s < minHalfSpanDeg * 2) {
      final mid = (n + s) / 2;
      s = mid - minHalfSpanDeg;
      n = mid + minHalfSpanDeg;
    }
    if (e - w < minHalfSpanDeg * 2) {
      final mid = (e + w) / 2;
      w = mid - minHalfSpanDeg;
      e = mid + minHalfSpanDeg;
    }
    return GribBBox(latMin: s, latMax: n, lonMin: w, lonMax: e)
        .padded(marginDeg);
  }
}

/// Free source catalog (v1: NOAA NOMADS GFS + Saildocs email already in app).
enum FreeGribSource {
  /// NOAA NOMADS GFS 0.25° grib filter — direct HTTP, no account.
  noaaGfs025,

  /// Saildocs email query (built elsewhere; not a direct HTTP download).
  saildocsEmail,
}

/// #281 — download free GRIB subsets for a planned area/route.
///
/// **NOAA NOMADS GFS 0.25°** (`filter_gfs_0p25.pl`) is free, no key, and
/// returns real GRIB2 for a lat/lon box (wind U/V at 10 m, optional MSLP).
/// Multi-hour forecasts are concatenated into one multi-message GRIB file and
/// persisted via [GribImportService] for the existing viewer.
class GribDownloadService {
  GribDownloadService({
    http.Client? client,
    GribImportService? importService,
    this.userAgent = 'SisuMate/1.0 (free GRIB; sailor app)',
  })  : _client = client ?? http.Client(),
        _ownsClient = client == null,
        _import = importService ?? GribImportService();

  final http.Client _client;
  final bool _ownsClient;
  final GribImportService _import;
  final String userAgent;

  static const networkTimeout = Duration(seconds: 90);

  void close() {
    if (_ownsClient) _client.close();
  }

  /// NOMADS expects longitudes in [0, 360] for leftlon/rightlon.
  static double lon0to360(double lon) {
    var x = lon % 360;
    if (x < 0) x += 360;
    return x;
  }

  /// #291 — NOAA GFS Wave filter URL (significant wave height / direction).
  static Uri buildNomadsGfsWaveUrl({
    required GribBBox box,
    required DateTime cycleUtc,
    required int forecastHour,
  }) {
    final b = box.normalized();
    final ymd =
        '${cycleUtc.year.toString().padLeft(4, '0')}${cycleUtc.month.toString().padLeft(2, '0')}${cycleUtc.day.toString().padLeft(2, '0')}';
    final cc = cycleUtc.hour.toString().padLeft(2, '0');
    final fh = forecastHour.toString().padLeft(3, '0');
    // Global wave product filename pattern (NOMADS gfswave).
    final file = 'gfswave.t${cc}z.global.0p25.f$fh.grib2';
    final left = lon0to360(b.lonMin);
    final right = lon0to360(b.lonMax);
    return Uri.https(
      'nomads.ncep.noaa.gov',
      '/cgi-bin/filter_gfswave.pl',
      {
        'file': file,
        'var_HTSGW': 'on',
        'var_DIRPW': 'on',
        'var_PERPW': 'on',
        'subregion': '',
        'leftlon': left.toStringAsFixed(2),
        'rightlon': right.toStringAsFixed(2),
        'toplat': b.latMax.toStringAsFixed(2),
        'bottomlat': b.latMin.toStringAsFixed(2),
        'dir': '/gfs.$ymd/$cc/wave/gridded',
      },
    );
  }

  /// Build a single forecast-hour filter URL (pure; for tests + dry-run).
  static Uri buildNomadsGfs025Url({
    required GribBBox box,
    required DateTime cycleUtc,
    required int forecastHour,
    bool pressureMsl = true,
  }) {
    final b = box.normalized();
    final ymd =
        '${cycleUtc.year.toString().padLeft(4, '0')}${cycleUtc.month.toString().padLeft(2, '0')}${cycleUtc.day.toString().padLeft(2, '0')}';
    final cc = cycleUtc.hour.toString().padLeft(2, '0');
    final fh = forecastHour.toString().padLeft(3, '0');
    final file = 'gfs.t${cc}z.pgrb2.0p25.f$fh';
    final left = lon0to360(b.lonMin);
    final right = lon0to360(b.lonMax);
    // If west of greenwich and east of greenwich mixed, left may be > right
    // in 0–360 space (e.g. 350 and 10). For v1 we assume non-crossing routes.
    final params = <String, String>{
      'file': file,
      'lev_10_m_above_ground': 'on',
      'var_UGRD': 'on',
      'var_VGRD': 'on',
      if (pressureMsl) ...{
        'lev_mean_sea_level': 'on',
        'var_PRMSL': 'on',
      },
      'subregion': '',
      'leftlon': left.toStringAsFixed(2),
      'rightlon': right.toStringAsFixed(2),
      'toplat': b.latMax.toStringAsFixed(2),
      'bottomlat': b.latMin.toStringAsFixed(2),
      'dir': '/gfs.$ymd/$cc/atmos',
    };
    return Uri.https(
      'nomads.ncep.noaa.gov',
      '/cgi-bin/filter_gfs_0p25.pl',
      params,
    );
  }

  /// Candidate GFS cycles: 00/06/12/18 UTC, newest first, lag for publish delay.
  static List<DateTime> candidateCycles(DateTime nowUtc, {int max = 6}) {
    final base = nowUtc.toUtc().subtract(const Duration(hours: 4));
    final out = <DateTime>[];
    var hour = (base.hour ~/ 6) * 6;
    var t = DateTime.utc(base.year, base.month, base.day, hour);
    for (var i = 0; i < max; i++) {
      out.add(t);
      t = t.subtract(const Duration(hours: 6));
    }
    return out;
  }

  /// Find the newest cycle that returns GRIB magic for f000 on [box].
  Future<DateTime?> resolveLatestCycle(GribBBox box) async {
    for (final cycle in candidateCycles(DateTime.now().toUtc())) {
      final uri = buildNomadsGfs025Url(
        box: box,
        cycleUtc: cycle,
        forecastHour: 0,
        pressureMsl: false,
      );
      try {
        final res = await _client
            .get(uri, headers: {'User-Agent': userAgent})
            .timeout(const Duration(seconds: 25));
        if (res.statusCode == 200 && _looksLikeGrib(res.bodyBytes)) {
          return cycle;
        }
      } catch (e) {
        unawaited(ErrorLogService().logWarning(
          'NOMADS cycle probe failed ($cycle): $e',
          context: 'grib_download_service: resolveLatestCycle',
        ));
      }
    }
    return null;
  }

  /// #291 — download free NOAA GFS Wave fields for [box].
  Future<GribDownloadResult> downloadNoaaGfsWave({
    required GribBBox box,
    List<int> forecastHours = const [0, 24, 48, 72],
    void Function(String status)? onProgress,
  }) async {
    final b = box.normalized();
    onProgress?.call('Finding GFS Wave cycle (NOAA NOMADS)…');
    DateTime? cycle;
    for (final c in candidateCycles(DateTime.now().toUtc())) {
      final uri = buildNomadsGfsWaveUrl(box: b, cycleUtc: c, forecastHour: 0);
      try {
        final res = await _client
            .get(uri, headers: {'User-Agent': userAgent})
            .timeout(const Duration(seconds: 25));
        if (res.statusCode == 200 && _looksLikeGrib(res.bodyBytes)) {
          cycle = c;
          break;
        }
      } catch (_) {}
    }
    if (cycle == null) {
      return const GribDownloadResult.failure(
        'No free NOAA GFS Wave cycle available — try wind GFS or Saildocs WAVES.',
      );
    }
    final hours = forecastHours.toSet().toList()..sort();
    final chunks = <int>[];
    var okHours = 0;
    for (final fh in hours) {
      onProgress?.call('Downloading GFS Wave f${fh.toString().padLeft(3, '0')}…');
      final uri =
          buildNomadsGfsWaveUrl(box: b, cycleUtc: cycle, forecastHour: fh);
      try {
        final res = await _client
            .get(uri, headers: {'User-Agent': userAgent})
            .timeout(networkTimeout);
        if (res.statusCode == 200 && _looksLikeGrib(res.bodyBytes)) {
          chunks.addAll(res.bodyBytes);
          okHours++;
        }
      } catch (_) {}
    }
    if (chunks.isEmpty) {
      return const GribDownloadResult.failure(
        'Wave download returned no GRIB data for this area.',
      );
    }
    final path = await _import.persistBytes(
      Uint8List.fromList(chunks),
      suggestedName:
          'gfswave_${cycle.toUtc().toIso8601String().substring(0, 13).replaceAll(':', '')}',
    );
    return GribDownloadResult.success(
      path: path,
      cycleUtc: cycle,
      hoursDownloaded: okHours,
      source: FreeGribSource.noaaGfs025,
      message:
          'Saved free NOAA GFS Wave ($okHours hour step(s)). Open GRIB viewer.',
    );
  }

  /// Download free NOAA GFS wind (+ MSLP) for [box] at [forecastHours].
  /// Returns app-storage path of the multi-message GRIB, or null on failure.
  Future<GribDownloadResult> downloadNoaaGfs({
    required GribBBox box,
    List<int> forecastHours = const [0, 24, 48, 72],
    void Function(String status)? onProgress,
  }) async {
    final b = box.normalized();
    onProgress?.call('Finding latest free GFS cycle (NOAA NOMADS)…');
    final cycle = await resolveLatestCycle(b);
    if (cycle == null) {
      return const GribDownloadResult.failure(
        'No free NOAA GFS cycle available right now — try again later, '
        'or use Saildocs email request.',
      );
    }
    final hours = forecastHours.toSet().toList()..sort();
    final chunks = <int>[];
    var okHours = 0;
    for (final fh in hours) {
      onProgress?.call(
        'Downloading GFS f${fh.toString().padLeft(3, '0')} '
        '(${cycle.toUtc().toIso8601String().substring(0, 13)}Z)…',
      );
      final uri = buildNomadsGfs025Url(
        box: b,
        cycleUtc: cycle,
        forecastHour: fh,
      );
      try {
        final res = await _client
            .get(uri, headers: {'User-Agent': userAgent})
            .timeout(networkTimeout);
        if (res.statusCode != 200 || !_looksLikeGrib(res.bodyBytes)) {
          unawaited(ErrorLogService().logWarning(
            'NOMADS f$fh status=${res.statusCode} bytes=${res.bodyBytes.length}',
            context: 'grib_download_service: downloadNoaaGfs',
          ));
          continue;
        }
        chunks.addAll(res.bodyBytes);
        okHours++;
      } catch (e) {
        unawaited(ErrorLogService().logWarning(
          'NOMADS f$fh failed: $e',
          context: 'grib_download_service: downloadNoaaGfs',
        ));
      }
    }
    if (chunks.isEmpty) {
      return const GribDownloadResult.failure(
        'Download returned no GRIB data for this area. Check connectivity '
        'or shrink the box.',
      );
    }
    onProgress?.call('Saving $okHours forecast hour(s)…');
    final path = await _import.persistBytes(
      Uint8List.fromList(chunks),
      suggestedName:
          'gfs_${cycle.toUtc().toIso8601String().substring(0, 13).replaceAll(':', '')}_'
          '${okHours}h',
    );
    return GribDownloadResult.success(
      path: path,
      cycleUtc: cycle,
      hoursDownloaded: okHours,
      source: FreeGribSource.noaaGfs025,
      message:
          'Saved free NOAA GFS ($okHours hour step(s) from ${cycle.toUtc()} UTC). '
          'Open the GRIB viewer to plot.',
    );
  }

  static bool _looksLikeGrib(List<int> bytes) {
    if (bytes.length < 8) return false;
    return bytes[0] == 0x47 && // G
        bytes[1] == 0x52 && // R
        bytes[2] == 0x49 && // I
        bytes[3] == 0x42; // B
  }
}

class GribDownloadResult {
  final bool ok;
  final String? path;
  final DateTime? cycleUtc;
  final int hoursDownloaded;
  final FreeGribSource? source;
  final String message;

  const GribDownloadResult.success({
    required this.path,
    required this.cycleUtc,
    required this.hoursDownloaded,
    required this.source,
    required this.message,
  }) : ok = true;

  const GribDownloadResult.failure(this.message)
      : ok = false,
        path = null,
        cycleUtc = null,
        hoursDownloaded = 0,
        source = null;
}
