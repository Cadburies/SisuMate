import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'error_log_service.dart';

/// #256 — connectivity layer for a PredictWind Datahub ("PW-Hub", a "HUB-32m"
/// device made by Remote Data Sensing LLC), reachable via a remote-access
/// tunnel (`remote.rdsensing.com`, dart-defines `PREDICTWIND_HUB_URL` /
/// `PREDICTWIND_HUB_HTTP_URL` + `PREDICTWIND_HUB_USERNAME` /
/// `PREDICTWIND_HUB_PASSWORD`).
///
/// Live-verified against the real device (2026-08-04): it's an OpenWrt/LuCI
/// admin interface, restricted to a small custom menu — logging in
/// (`POST /cgi-bin/luci` with `luci_username`/`luci_password`, LuCI's
/// standard form) returns a `sysauth` session cookie on success. Behind
/// that login is a genuine NMEA bridge (`nmead`) with a live-data JSON
/// endpoint at `admin/services/nmead/nmead_status` — confirmed to return
/// real GPS (`lat`/`lon`/`sog`/`cog`) and wind (`tws`/`twd`/`aws`/`awa`)
/// fields, among others (depth, heading, roll/pitch, sea temperature) not
/// yet surfaced by [PredictWindBoatData]. No unauthenticated path was found
/// (`/signalk*` on the same tunneled ports both 404) — a session is
/// required for every fetch.
///
/// #257/#260 — the HTTPS endpoint (`PREDICTWIND_HUB_URL`) serves a
/// self-signed certificate, which `curl -k` masked during dev testing but
/// which `dart:io`'s real certificate validation correctly rejects on a
/// real device (`HandshakeException: CERTIFICATE_VERIFY_FAILED: self
/// signed certificate`) — every real-device connection attempt failed.
/// [_baseUrl] therefore prefers the plain-HTTP endpoint
/// (`PREDICTWIND_HUB_HTTP_URL`), which the vendor provisions as a
/// documented alternative access path, not a workaround. This trades
/// transport encryption for a connection that actually works; the more
/// correct fix (pinning the HTTPS cert's actual fingerprint instead of
/// rejecting or blindly trusting it) is a reasonable follow-up if this
/// grows beyond a single-boat prototype.
enum PredictWindHubConnectionState {
  notConfigured,
  missingCredentials,
  connected,
  authFailed,
  unreachable,
}

class PredictWindHubStatus {
  final PredictWindHubConnectionState state;
  final String? detail;
  const PredictWindHubStatus(this.state, {this.detail});
}

class PredictWindBoatData {
  final double? latitude;
  final double? longitude;
  final double? windSpeedKt;
  final double? windDirectionDeg;
  /// Water depth in meters (`dpt` — below transducer + offset). Used by the
  /// Anchor Alarm to suggest a scope-based geofence radius.
  final double? depthMeters;
  final DateTime observedAt;
  const PredictWindBoatData({
    this.latitude,
    this.longitude,
    this.windSpeedKt,
    this.windDirectionDeg,
    this.depthMeters,
    required this.observedAt,
  });

  /// #256 follow-up — true once [observedAt] is older than [maxAge]. The
  /// Hub can stay reachable and keep answering with its *last-known*
  /// reading even after the boat's NMEA instruments are switched off (the
  /// Hub itself may stay powered independently) — a frozen `unixtime` is
  /// how that's told apart from a genuinely live feed. Anchor-alarm
  /// evaluation and position display must treat a stale reading the same
  /// as "no fix", not as a trustworthy current position.
  bool isStale({Duration maxAge = const Duration(seconds: 60)}) =>
      DateTime.now().toUtc().difference(observedAt) > maxAge;

  /// True when there's a fresh, usable position fix — the single check
  /// both the position display and alarm evaluation should gate on.
  bool get hasFix => latitude != null && longitude != null && !isStale();
}

class PredictWindDatahubService {
  /// The override params are a test-only seam — the real values are
  /// normally baked in at compile time via `String.fromEnvironment`, which
  /// can't be overridden at `flutter test` runtime the way `--dart-define`
  /// sets them for a real build.
  const PredictWindDatahubService({
    String? baseUrlOverride,
    String? usernameOverride,
    String? passwordOverride,
  })  : _baseUrlOverride = baseUrlOverride,
        _usernameOverride = usernameOverride,
        _passwordOverride = passwordOverride;

  final String? _baseUrlOverride;
  final String? _usernameOverride;
  final String? _passwordOverride;

  static const _hubUrl = String.fromEnvironment('PREDICTWIND_HUB_URL');
  static const _hubHttpUrl =
      String.fromEnvironment('PREDICTWIND_HUB_HTTP_URL');
  static const _hubUsername =
      String.fromEnvironment('PREDICTWIND_HUB_USERNAME');
  static const _hubPassword =
      String.fromEnvironment('PREDICTWIND_HUB_PASSWORD');
  static const _timeout = Duration(seconds: 8);
  static const _loginPath = 'cgi-bin/luci';
  static const _statusPath = 'cgi-bin/luci/admin/services/nmead/nmead_status';
  static final _sysauthCookie = RegExp(r'sysauth=([0-9a-fA-F]+)');

  String? get _baseUrl =>
      _baseUrlOverride ??
      (_hubHttpUrl.isNotEmpty
          ? _hubHttpUrl
          : (_hubUrl.isNotEmpty ? _hubUrl : null));

  String get _username => _usernameOverride ?? _hubUsername;
  String get _password => _passwordOverride ?? _hubPassword;

  bool get isConfigured => _baseUrl != null;
  bool get hasCredentials => _username.isNotEmpty && _password.isNotEmpty;

  Future<PredictWindHubStatus> checkConnection({http.Client? client}) async {
    final base = _baseUrl;
    if (base == null) {
      return const PredictWindHubStatus(
          PredictWindHubConnectionState.notConfigured);
    }
    if (!hasCredentials) {
      return const PredictWindHubStatus(
          PredictWindHubConnectionState.missingCredentials);
    }
    final c = client ?? http.Client();
    try {
      final sysauth = await _login(c, base);
      return PredictWindHubStatus(sysauth != null
          ? PredictWindHubConnectionState.connected
          : PredictWindHubConnectionState.authFailed);
    } catch (e) {
      unawaited(ErrorLogService().logWarning(
        'PredictWind Hub unreachable: $e',
        context: 'predictwind_datahub_service: checkConnection',
      ));
      return PredictWindHubStatus(
        PredictWindHubConnectionState.unreachable,
        detail: e.toString(),
      );
    } finally {
      if (client == null) c.close();
    }
  }

  Future<PredictWindBoatData?> fetchBoatData({http.Client? client}) async {
    final base = _baseUrl;
    if (base == null || !hasCredentials) return null;
    final c = client ?? http.Client();
    try {
      final sysauth = await _login(c, base);
      if (sysauth == null) return null;

      final res = await c
          .get(
            Uri.parse('$base/$_statusPath'),
            headers: {'Cookie': 'sysauth=$sysauth'},
          )
          .timeout(_timeout);
      if (res.statusCode != 200) return null;

      final json = jsonDecode(res.body) as Map<String, dynamic>;
      final unixtime = json['unixtime'];
      // GPS fix-quality (NMEA GGA convention: 0 = no fix). Absent/
      // unparseable is treated as "unknown", not "no fix" — only an
      // explicit 0 zeroes out the position, so a Hub that doesn't report
      // this field at all still gets a usable fix.
      final quality = json['quality'];
      final hasFix = quality is! num || quality > 0;
      return PredictWindBoatData(
        latitude: hasFix ? _asDouble(json['lat']) : null,
        longitude: hasFix ? _asDouble(json['lon']) : null,
        windSpeedKt: _asDouble(json['tws']),
        windDirectionDeg: _asDouble(json['twd']),
        depthMeters: _asDouble(json['dpt']),
        observedAt: unixtime is num
            ? DateTime.fromMillisecondsSinceEpoch(
                unixtime.toInt() * 1000,
                isUtc: true,
              )
            : DateTime.now(),
      );
    } catch (e) {
      unawaited(ErrorLogService().logWarning(
        'PredictWind Hub fetchBoatData failed: $e',
        context: 'predictwind_datahub_service: fetchBoatData',
      ));
      return null;
    } finally {
      if (client == null) c.close();
    }
  }

  /// LuCI's standard login form (`luci_username`/`luci_password`) — a
  /// successful login redirects (`302`) with a `Set-Cookie: sysauth=...`
  /// session token; a failed one re-renders the same login page.
  Future<String?> _login(http.Client c, String base) async {
    final res = await c.post(
      Uri.parse('$base/$_loginPath'),
      body: {'luci_username': _username, 'luci_password': _password},
    ).timeout(_timeout);
    final setCookie = res.headers['set-cookie'];
    if (setCookie == null) return null;
    return _sysauthCookie.firstMatch(setCookie)?.group(1);
  }

  double? _asDouble(dynamic v) => v is num ? v.toDouble() : null;
}
