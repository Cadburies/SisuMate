import 'dart:async';
import 'dart:convert';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:http/http.dart' as http;

import 'error_log_service.dart';

/// #256/#263 — connectivity layer for a PredictWind Datahub ("PW-Hub", a
/// "HUB-32m" device made by Remote Data Sensing LLC), reachable two ways:
/// - **local** (`PREDICTWIND_HUB_LOCAL_URL`) — the boat's own WiFi network,
///   fast and needs no internet, but only reachable when the phone is
///   physically on that network;
/// - **remote** (`PREDICTWIND_HUB_URL`/`PREDICTWIND_HUB_HTTP_URL`) — the
///   internet/remote-access tunnel (`remote.rdsensing.com`), reachable from
///   anywhere (e.g. a beach bar) but depends on internet + the tunnel.
///
/// [_candidateBaseUrls] tries local first, but only when the phone is
/// actually on WiFi (`connectivity_plus`) — off WiFi, local isn't worth
/// attempting at all — then falls back to remote either way. Both
/// [checkConnection] and [fetchBoatData] try each candidate in order and
/// use the first one that works; [PredictWindHubStatus.viaLocalNetwork] /
/// [PredictWindBoatData.viaLocalNetwork] record which one did, so the UI
/// can show the user which path is actually active.
///
/// Both endpoints (once configured) speak the *same* LuCI/`nmead` API —
/// logging in (`POST /cgi-bin/luci` with `luci_username`/`luci_password`,
/// LuCI's standard form) returns a `sysauth` session cookie on success.
/// Behind that login is a genuine NMEA bridge (`nmead`) with a live-data
/// JSON endpoint at `admin/services/nmead/nmead_status` — confirmed to
/// return real GPS (`lat`/`lon`/`sog`/`cog`) and wind (`tws`/`twd`/`aws`/
/// `awa`) fields, among others (depth, heading, roll/pitch, sea
/// temperature) not yet surfaced by [PredictWindBoatData]. No
/// unauthenticated path was found (`/signalk*` on the same tunneled ports
/// both 404) — a session is required for every fetch.
///
/// #263 — [PREDICTWIND_HUB_LOCAL_URL]'s default value is **unverified**: it
/// was set to `http://10.10.10.1`, PredictWind's own documented default
/// device IP for connecting chartplotter apps to the DataHub's WiFi
/// (https://help.predictwind.com/en/articles/8332728), as a starting
/// hypothesis to test against — not confirmed to be where *this* device's
/// LuCI/nmead service actually answers locally. Verify live before relying
/// on it; update the dart-define if the real local address differs.
///
/// #257/#260 — the HTTPS remote endpoint (`PREDICTWIND_HUB_URL`) serves a
/// self-signed certificate, which `curl -k` masked during dev testing but
/// which `dart:io`'s real certificate validation correctly rejects on a
/// real device (`HandshakeException: CERTIFICATE_VERIFY_FAILED: self
/// signed certificate`) — every real-device connection attempt failed.
/// [_remoteBaseUrl] therefore prefers the plain-HTTP endpoint
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
  final bool viaLocalNetwork;
  const PredictWindHubStatus(
    this.state, {
    this.detail,
    this.viaLocalNetwork = false,
  });
}

class PredictWindBoatData {
  final double? latitude;
  final double? longitude;
  final double? windSpeedKt;
  final double? windDirectionDeg;
  /// Water depth in meters (`dpt` — below transducer + offset). Used by the
  /// Anchor Alarm to suggest a scope-based geofence radius.
  final double? depthMeters;
  /// #263 — true when this reading came from the boat's local WiFi rather
  /// than the internet/remote-access tunnel.
  final bool viaLocalNetwork;
  final DateTime observedAt;
  const PredictWindBoatData({
    this.latitude,
    this.longitude,
    this.windSpeedKt,
    this.windDirectionDeg,
    this.depthMeters,
    this.viaLocalNetwork = false,
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
    String? localBaseUrlOverride,
    String? usernameOverride,
    String? passwordOverride,
    Connectivity? connectivityOverride,
  })  : _baseUrlOverride = baseUrlOverride,
        _localBaseUrlOverride = localBaseUrlOverride,
        _usernameOverride = usernameOverride,
        _passwordOverride = passwordOverride,
        _connectivityOverride = connectivityOverride;

  final String? _baseUrlOverride;
  final String? _localBaseUrlOverride;
  final String? _usernameOverride;
  final String? _passwordOverride;
  final Connectivity? _connectivityOverride;

  static const _hubUrl = String.fromEnvironment('PREDICTWIND_HUB_URL');
  static const _hubHttpUrl =
      String.fromEnvironment('PREDICTWIND_HUB_HTTP_URL');
  static const _hubLocalUrl =
      String.fromEnvironment('PREDICTWIND_HUB_LOCAL_URL');
  static const _hubUsername =
      String.fromEnvironment('PREDICTWIND_HUB_USERNAME');
  static const _hubPassword =
      String.fromEnvironment('PREDICTWIND_HUB_PASSWORD');
  static const _remoteTimeout = Duration(seconds: 8);
  // Local should be fast if it's there at all — no point waiting as long
  // as the remote tunnel before falling back.
  static const _localTimeout = Duration(seconds: 4);
  static const _loginPath = 'cgi-bin/luci';
  static const _statusPath = 'cgi-bin/luci/admin/services/nmead/nmead_status';
  static final _sysauthCookie = RegExp(r'sysauth=([0-9a-fA-F]+)');

  String? get _remoteBaseUrl =>
      _baseUrlOverride ??
      (_hubHttpUrl.isNotEmpty
          ? _hubHttpUrl
          : (_hubUrl.isNotEmpty ? _hubUrl : null));

  String? get _localBaseUrl =>
      _localBaseUrlOverride ?? (_hubLocalUrl.isNotEmpty ? _hubLocalUrl : null);

  String get _username => _usernameOverride ?? _hubUsername;
  String get _password => _passwordOverride ?? _hubPassword;

  bool get isConfigured => _remoteBaseUrl != null || _localBaseUrl != null;
  bool get hasCredentials => _username.isNotEmpty && _password.isNotEmpty;

  /// Candidate base URLs in priority order: local first, but only when the
  /// phone is actually on WiFi right now (off WiFi, the boat's local
  /// network isn't reachable at all, so trying it would just waste time);
  /// remote after that, regardless of WiFi state, as the fallback that
  /// works from anywhere. Local-only config with no WiFi → empty list.
  Future<List<_Candidate>> _candidateBaseUrls() async {
    final local = _localBaseUrl;
    final remote = _remoteBaseUrl;
    final candidates = <_Candidate>[];
    if (local != null) {
      final connectivity =
          await (_connectivityOverride ?? Connectivity()).checkConnectivity();
      if (connectivity.contains(ConnectivityResult.wifi)) {
        candidates.add(_Candidate(local, isLocal: true, timeout: _localTimeout));
      }
    }
    if (remote != null) {
      candidates.add(_Candidate(remote, isLocal: false, timeout: _remoteTimeout));
    }
    return candidates;
  }

  Future<PredictWindHubStatus> checkConnection({http.Client? client}) async {
    if (!isConfigured) {
      return const PredictWindHubStatus(
          PredictWindHubConnectionState.notConfigured);
    }
    if (!hasCredentials) {
      return const PredictWindHubStatus(
          PredictWindHubConnectionState.missingCredentials);
    }
    final candidates = await _candidateBaseUrls();
    if (candidates.isEmpty) {
      return const PredictWindHubStatus(
        PredictWindHubConnectionState.unreachable,
        detail: 'Not on WiFi — the local Hub URL is only reachable on the '
            "boat's own network.",
      );
    }

    final c = client ?? http.Client();
    try {
      var lastState = PredictWindHubConnectionState.unreachable;
      String? lastDetail;
      for (final candidate in candidates) {
        try {
          final sysauth = await _login(c, candidate.baseUrl, candidate.timeout);
          if (sysauth != null) {
            return PredictWindHubStatus(
              PredictWindHubConnectionState.connected,
              viaLocalNetwork: candidate.isLocal,
            );
          }
          lastState = PredictWindHubConnectionState.authFailed;
          lastDetail = null;
        } catch (e) {
          lastState = PredictWindHubConnectionState.unreachable;
          lastDetail = e.toString();
        }
      }
      if (lastState == PredictWindHubConnectionState.unreachable) {
        unawaited(ErrorLogService().logWarning(
          'PredictWind Hub unreachable: $lastDetail',
          context: 'predictwind_datahub_service: checkConnection',
        ));
      }
      return PredictWindHubStatus(lastState, detail: lastDetail);
    } finally {
      if (client == null) c.close();
    }
  }

  Future<PredictWindBoatData?> fetchBoatData({http.Client? client}) async {
    if (!hasCredentials) return null;
    final candidates = await _candidateBaseUrls();
    if (candidates.isEmpty) return null;

    final c = client ?? http.Client();
    try {
      for (final candidate in candidates) {
        try {
          final sysauth = await _login(c, candidate.baseUrl, candidate.timeout);
          if (sysauth == null) continue;

          final res = await c
              .get(
                Uri.parse('${candidate.baseUrl}/$_statusPath'),
                headers: {'Cookie': 'sysauth=$sysauth'},
              )
              .timeout(candidate.timeout);
          if (res.statusCode != 200) continue;

          final json = jsonDecode(res.body) as Map<String, dynamic>;
          final unixtime = json['unixtime'];
          // GPS fix-quality (NMEA GGA convention: 0 = no fix). Absent/
          // unparseable is treated as "unknown", not "no fix" — only an
          // explicit 0 zeroes out the position, so a Hub that doesn't
          // report this field at all still gets a usable fix.
          final quality = json['quality'];
          final hasFix = quality is! num || quality > 0;
          return PredictWindBoatData(
            latitude: hasFix ? _asDouble(json['lat']) : null,
            longitude: hasFix ? _asDouble(json['lon']) : null,
            windSpeedKt: _asDouble(json['tws']),
            windDirectionDeg: _asDouble(json['twd']),
            depthMeters: _asDouble(json['dpt']),
            viaLocalNetwork: candidate.isLocal,
            observedAt: unixtime is num
                ? DateTime.fromMillisecondsSinceEpoch(
                    unixtime.toInt() * 1000,
                    isUtc: true,
                  )
                : DateTime.now(),
          );
        } catch (e) {
          unawaited(ErrorLogService().logWarning(
            'PredictWind Hub fetchBoatData failed (${candidate.isLocal ? 'local' : 'remote'}): $e',
            context: 'predictwind_datahub_service: fetchBoatData',
          ));
        }
      }
      return null;
    } finally {
      if (client == null) c.close();
    }
  }

  /// LuCI's standard login form (`luci_username`/`luci_password`) — a
  /// successful login redirects (`302`) with a `Set-Cookie: sysauth=...`
  /// session token; a failed one re-renders the same login page.
  Future<String?> _login(http.Client c, String base, Duration timeout) async {
    final res = await c.post(
      Uri.parse('$base/$_loginPath'),
      body: {'luci_username': _username, 'luci_password': _password},
    ).timeout(timeout);
    final setCookie = res.headers['set-cookie'];
    if (setCookie == null) return null;
    return _sysauthCookie.firstMatch(setCookie)?.group(1);
  }

  double? _asDouble(dynamic v) => v is num ? v.toDouble() : null;
}

class _Candidate {
  final String baseUrl;
  final bool isLocal;
  final Duration timeout;
  const _Candidate(this.baseUrl, {required this.isLocal, required this.timeout});
}
