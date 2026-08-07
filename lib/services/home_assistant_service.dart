import 'dart:convert';

import 'package:http/http.dart' as http;

import 'predictwind_datahub_service.dart';

/// #263 — Home Assistant REST client for boat instruments (GPS/wind/depth).
///
/// Uses a **long-lived access token** (`Authorization: Bearer …`) against:
/// - `GET /api/` — reachability + auth check
/// - `GET /api/states/<entity_id>` — entity state / attributes
///
/// GPS can come from:
/// 1. A single [gpsEntity] with `latitude`/`longitude` attributes
///    (typical `device_tracker.*` / `person.*`), or
/// 2. Separate [latEntity] / [lonEntity] sensors whose `state` is the value.
///
/// Local URL (boat LAN) and optional remote URL (Nabu Casa / reverse proxy)
/// are separate candidates in [BoatInstrumentFailoverService].
class HomeAssistantService {
  const HomeAssistantService({
    this.baseUrl,
    this.token,
    this.gpsEntity,
    this.latEntity,
    this.lonEntity,
    this.windSpeedEntity,
    this.windDirEntity,
    this.depthEntity,
  });

  final String? baseUrl;
  final String? token;
  final String? gpsEntity;
  final String? latEntity;
  final String? lonEntity;
  final String? windSpeedEntity;
  final String? windDirEntity;
  final String? depthEntity;

  static const _localTimeout = Duration(seconds: 4);
  static const _remoteTimeout = Duration(seconds: 8);

  /// Compile-time defaults for debug (empty unless dart-defines set).
  static const defaultUrl = String.fromEnvironment('HA_URL');
  static const defaultRemoteUrl = String.fromEnvironment('HA_REMOTE_URL');
  static const defaultToken = String.fromEnvironment('HA_TOKEN');
  static const defaultGpsEntity =
      String.fromEnvironment('HA_GPS_ENTITY');
  static const defaultLatEntity =
      String.fromEnvironment('HA_LAT_ENTITY');
  static const defaultLonEntity =
      String.fromEnvironment('HA_LON_ENTITY');
  static const defaultWindSpeedEntity =
      String.fromEnvironment('HA_WIND_SPEED_ENTITY');
  static const defaultWindDirEntity =
      String.fromEnvironment('HA_WIND_DIR_ENTITY');
  static const defaultDepthEntity =
      String.fromEnvironment('HA_DEPTH_ENTITY');

  static String _asHttpBase(String raw) {
    final t = raw.trim();
    if (t.isEmpty) return t;
    if (t.startsWith('http://') || t.startsWith('https://')) {
      return t.endsWith('/') ? t.substring(0, t.length - 1) : t;
    }
    return 'http://$t';
  }

  bool get isConfigured =>
      (baseUrl?.trim().isNotEmpty ?? false) &&
      (token?.trim().isNotEmpty ?? false);

  bool get hasGpsConfig =>
      (gpsEntity?.trim().isNotEmpty ?? false) ||
      ((latEntity?.trim().isNotEmpty ?? false) &&
          (lonEntity?.trim().isNotEmpty ?? false));

  Map<String, String> get _headers => {
        'Authorization': 'Bearer ${token!.trim()}',
        'Content-Type': 'application/json',
      };

  Duration _timeoutFor(String url) =>
      PredictWindDatahubService.isPrivateLanUrl(url)
          ? _localTimeout
          : _remoteTimeout;

  /// `GET /api/` — 200 + message means token + host are good.
  Future<GatewayProbeResult> probeConnection({http.Client? client}) async {
    if (!isConfigured) {
      return const GatewayProbeResult(
        ok: false,
        detail: 'Enter Home Assistant URL and long-lived access token.',
      );
    }
    final base = _asHttpBase(baseUrl!);
    final c = client ?? http.Client();
    try {
      final res = await c
          .get(Uri.parse('$base/api/'), headers: _headers)
          .timeout(_timeoutFor(base));
      if (res.statusCode == 200) {
        return GatewayProbeResult(
          ok: true,
          detail: 'Home Assistant API OK at $base.',
        );
      }
      if (res.statusCode == 401 || res.statusCode == 403) {
        return const GatewayProbeResult(
          ok: false,
          detail: "Couldn't authenticate — check the long-lived access token.",
        );
      }
      return GatewayProbeResult(
        ok: false,
        detail: 'Home Assistant answered HTTP ${res.statusCode}.',
      );
    } catch (e) {
      return GatewayProbeResult(
        ok: false,
        detail: _friendlyHaProbeError(e, base),
      );
    } finally {
      if (client == null) c.close();
    }
  }

  /// #312 — DNS / mDNS failures get an HA-specific hint (phones often
  /// cannot resolve `homeassistant.local`; LAN IP always works).
  static String _friendlyHaProbeError(Object e, String baseUrl) {
    final raw = e.toString().toLowerCase();
    final dns = raw.contains('failed host lookup') ||
        raw.contains('no address associated') ||
        raw.contains('name or service not known') ||
        raw.contains('nodename nor servname') ||
        raw.contains('temporary failure in name resolution');
    if (!dns) return friendlyConnectionError(e);

    final host = Uri.tryParse(baseUrl)?.host ?? '';
    final isLocalMdns = host.endsWith('.local');
    if (isLocalMdns) {
      return 'Could not resolve "$host" (mDNS/.local often fails on phones). '
          'Use the Home Assistant LAN IP instead '
          '(e.g. http://192.168.0.20:8123).';
    }
    if (host.isNotEmpty) {
      return 'Could not resolve "$host". Try the device IP on boat WiFi '
          '(e.g. http://192.168.0.20:8123).';
    }
    return friendlyConnectionError(e);
  }

  /// Pull GPS (+ optional wind/depth) into [PredictWindBoatData].
  Future<PredictWindBoatData?> fetchBoatData({
    http.Client? client,
    bool viaLocalNetwork = false,
    String? sourceLabel,
  }) async {
    if (!isConfigured || !hasGpsConfig) return null;
    final base = _asHttpBase(baseUrl!);
    final c = client ?? http.Client();
    try {
      double? lat;
      double? lon;
      DateTime observedAt = DateTime.now().toUtc();

      final gpsId = gpsEntity?.trim() ?? '';
      if (gpsId.isNotEmpty) {
        final state = await _getState(c, base, gpsId);
        if (state == null) return null;
        final attrs = state['attributes'];
        if (attrs is Map) {
          lat = _asDouble(attrs['latitude']);
          lon = _asDouble(attrs['longitude']);
        }
        // Some integrations put lat/lon in state as "lat,lon"
        if (lat == null || lon == null) {
          final pair = _parseLatLonPair(state['state']?.toString());
          lat ??= pair?.$1;
          lon ??= pair?.$2;
        }
        observedAt = _parseHaTime(state['last_updated']) ?? observedAt;
      } else {
        final latState =
            await _getState(c, base, latEntity!.trim());
        final lonState =
            await _getState(c, base, lonEntity!.trim());
        if (latState == null || lonState == null) return null;
        lat = _asDouble(latState['state']) ??
            _asDouble((latState['attributes'] as Map?)?['latitude']);
        lon = _asDouble(lonState['state']) ??
            _asDouble((lonState['attributes'] as Map?)?['longitude']);
        observedAt = _parseHaTime(latState['last_updated']) ??
            _parseHaTime(lonState['last_updated']) ??
            observedAt;
      }

      if (lat == null || lon == null) return null;

      double? windKt;
      double? windDir;
      double? depthM;

      final windSp = windSpeedEntity?.trim() ?? '';
      if (windSp.isNotEmpty) {
        final s = await _getState(c, base, windSp);
        windKt = _asDouble(s?['state']);
        // HA often reports m/s — if unit_of_measurement is m/s, convert.
        final unit =
            (s?['attributes'] as Map?)?['unit_of_measurement']?.toString();
        if (windKt != null && unit != null && unit.toLowerCase().contains('m/s')) {
          windKt = windKt * 1.943844; // m/s → kn
        }
      }
      final windD = windDirEntity?.trim() ?? '';
      if (windD.isNotEmpty) {
        final s = await _getState(c, base, windD);
        windDir = _asDouble(s?['state']);
      }
      final depthE = depthEntity?.trim() ?? '';
      if (depthE.isNotEmpty) {
        final s = await _getState(c, base, depthE);
        depthM = _asDouble(s?['state']);
        final unit =
            (s?['attributes'] as Map?)?['unit_of_measurement']?.toString();
        if (depthM != null &&
            unit != null &&
            (unit.toLowerCase().contains('ft') ||
                unit.toLowerCase().contains('feet'))) {
          depthM = depthM * 0.3048;
        }
      }

      return PredictWindBoatData(
        latitude: lat,
        longitude: lon,
        windSpeedKt: windKt,
        windDirectionDeg: windDir,
        depthMeters: depthM,
        viaLocalNetwork: viaLocalNetwork,
        sourceLabel: sourceLabel ??
            (viaLocalNetwork
                ? 'Home Assistant (local)'
                : 'Home Assistant (internet)'),
        observedAt: observedAt,
      );
    } catch (_) {
      return null;
    } finally {
      if (client == null) c.close();
    }
  }

  Future<Map<String, dynamic>?> _getState(
    http.Client c,
    String base,
    String entityId,
  ) async {
    final res = await c
        .get(
          Uri.parse('$base/api/states/$entityId'),
          headers: _headers,
        )
        .timeout(_timeoutFor(base));
    if (res.statusCode != 200) return null;
    final decoded = jsonDecode(res.body);
    if (decoded is Map<String, dynamic>) return decoded;
    if (decoded is Map) return Map<String, dynamic>.from(decoded);
    return null;
  }

  static double? _asDouble(dynamic v) {
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v.trim());
    return null;
  }

  static (double, double)? _parseLatLonPair(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    final parts = raw.split(RegExp(r'[, ]+'));
    if (parts.length < 2) return null;
    final a = double.tryParse(parts[0]);
    final b = double.tryParse(parts[1]);
    if (a == null || b == null) return null;
    return (a, b);
  }

  static DateTime? _parseHaTime(dynamic raw) {
    if (raw is! String || raw.isEmpty) return null;
    return DateTime.tryParse(raw)?.toUtc();
  }

  /// Build from [UserSettings] (+ dart-define fallbacks) for a local base.
  factory HomeAssistantService.localFromSettings({
    required String? settingsUrl,
    required String? settingsToken,
    required String? gpsEntity,
    required String? latEntity,
    required String? lonEntity,
    required String? windSpeedEntity,
    required String? windDirEntity,
    required String? depthEntity,
  }) {
    final url = (settingsUrl != null && settingsUrl.trim().isNotEmpty)
        ? settingsUrl
        : (defaultUrl.isNotEmpty ? defaultUrl : null);
    final token = (settingsToken != null && settingsToken.trim().isNotEmpty)
        ? settingsToken
        : (defaultToken.isNotEmpty ? defaultToken : null);
    return HomeAssistantService(
      baseUrl: url,
      token: token,
      gpsEntity: _pick(gpsEntity, defaultGpsEntity),
      latEntity: _pick(latEntity, defaultLatEntity),
      lonEntity: _pick(lonEntity, defaultLonEntity),
      windSpeedEntity: _pick(windSpeedEntity, defaultWindSpeedEntity),
      windDirEntity: _pick(windDirEntity, defaultWindDirEntity),
      depthEntity: _pick(depthEntity, defaultDepthEntity),
    );
  }

  factory HomeAssistantService.remoteFromSettings({
    required String? settingsRemoteUrl,
    required String? settingsToken,
    required String? gpsEntity,
    required String? latEntity,
    required String? lonEntity,
    required String? windSpeedEntity,
    required String? windDirEntity,
    required String? depthEntity,
  }) {
    final url =
        (settingsRemoteUrl != null && settingsRemoteUrl.trim().isNotEmpty)
            ? settingsRemoteUrl
            : (defaultRemoteUrl.isNotEmpty ? defaultRemoteUrl : null);
    final token = (settingsToken != null && settingsToken.trim().isNotEmpty)
        ? settingsToken
        : (defaultToken.isNotEmpty ? defaultToken : null);
    return HomeAssistantService(
      baseUrl: url,
      token: token,
      gpsEntity: _pick(gpsEntity, defaultGpsEntity),
      latEntity: _pick(latEntity, defaultLatEntity),
      lonEntity: _pick(lonEntity, defaultLonEntity),
      windSpeedEntity: _pick(windSpeedEntity, defaultWindSpeedEntity),
      windDirEntity: _pick(windDirEntity, defaultWindDirEntity),
      depthEntity: _pick(depthEntity, defaultDepthEntity),
    );
  }

  static String? _pick(String? settings, String env) {
    if (settings != null && settings.trim().isNotEmpty) return settings.trim();
    if (env.isNotEmpty) return env;
    return null;
  }
}
