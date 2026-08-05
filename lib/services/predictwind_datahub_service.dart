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
/// #263 — [PREDICTWIND_HUB_LOCAL_URL] is boat-specific, not a fixed
/// default: `10.10.10.1` (PredictWind's own documented device IP for
/// chartplotter apps, https://help.predictwind.com/en/articles/8332728) is
/// only what a Hub answers on *if* it's the sole device on its own small
/// network. On this boat the Hub instead sits on a dedicated IoT VLAN
/// (`Sisu-IoT`, separate from the main `Sisu` WiFi7/MLO network because
/// most IoT gear doesn't speak MLO) with a static reservation at
/// `192.168.10.31` — confirmed and set in `dart-defines.json`. A phone on
/// the *main* network still can't reach that address unless the router
/// (here, a GL-iNet GL-BE9300) is configured to route between the two
/// subnets, or the phone joins the IoT network directly — this service has
/// no way to fix that itself; it can only time out on "local" and fall
/// back to remote when the two subnets aren't bridged. A Yacht Devices
/// YDWG-02 on the same IoT VLAN was set up alongside the Hub at
/// `192.168.10.30` — not yet integrated (see [knownLocalAddresses]'s doc).
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
/// #270 — user-facing copy for a Hub connection failure. A real on-device
/// report showed the *raw* `ClientException`/`SocketException` string
/// (`"...errno = 61), address = remote.rdsensing.com, port = 51169..."`)
/// surfacing verbatim in [PredictWindHubStatus.detail] and from there into
/// [AnchorAlarmScreen]'s Hub status card — meaningless to a sailor and not
/// something the app can act on either. The full raw string is still kept
/// (separately) for the local error log, where it remains useful for
/// debugging; this is only for what a person actually reads. Matches the
/// `friendlyError` pattern in `join_boat_service.dart`.
String friendlyConnectionError(Object e) {
  final s = e.toString().toLowerCase();
  if (s.contains('timeoutexception')) {
    return 'Timed out waiting for a response.';
  }
  if (s.contains('connection refused')) {
    return "Connection refused — the Hub isn't accepting connections right "
        'now.';
  }
  if (s.contains('failed host lookup') ||
      s.contains('no address associated')) {
    return "Can't find that address — check the Hub's network settings.";
  }
  if (s.contains('network is unreachable') ||
      s.contains('no route to host')) {
    return 'Network unreachable.';
  }
  if (s.contains('certificate') || s.contains('handshake')) {
    return 'Secure connection failed.';
  }
  return "Check the boat's network connection.";
}

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
      String? lastRawDetail;
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
          lastRawDetail = null;
          lastDetail = null;
        } catch (e) {
          lastState = PredictWindHubConnectionState.unreachable;
          lastRawDetail = e.toString();
          lastDetail = friendlyConnectionError(e);
        }
      }
      if (lastState == PredictWindHubConnectionState.unreachable) {
        unawaited(ErrorLogService().logWarning(
          'PredictWind Hub unreachable: $lastRawDetail',
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

  /// #263 — known default **local-WiFi** addresses for PredictWind Datahub-
  /// family devices. Includes PredictWind's documented default
  /// (`10.10.10.1`) plus the compile-time [PREDICTWIND_HUB_LOCAL_URL] when
  /// set (this boat: `http://192.168.10.31`). A bare Yacht Devices YDWG-02
  /// still wouldn't answer LuCI login (raw-NMEA — deferred in #263).
  static List<String> get knownLocalAddresses {
    final list = <String>['http://10.10.10.1'];
    if (_hubLocalUrl.isNotEmpty && !list.contains(_hubLocalUrl)) {
      list.insert(0, _hubLocalUrl);
    }
    return list;
  }

  /// #263 follow-up — PredictWind / RDS **internet tunnel** base URLs tried
  /// by Discover when you're not on the boat WiFi (beach bar, marina cafe).
  /// HTTP first: the HTTPS endpoint uses a self-signed cert that dart:io
  /// rejects (#257/#260). Compile-time dart-defines are preferred when set;
  /// the vendor hostnames are always included as a fallback so Discover
  /// still works without rebuilds after a tunnel port change is typed in.
  static List<String> get knownRemoteAddresses {
    final list = <String>[];
    void add(String? url) {
      if (url == null || url.isEmpty) return;
      if (!list.contains(url)) list.add(url);
    }

    add(_hubHttpUrl.isNotEmpty ? _hubHttpUrl : null);
    add(_hubUrl.isNotEmpty ? _hubUrl : null);
    // Vendor defaults (same host family as dart-defines).
    add('http://remote.rdsensing.com:36121');
    add('https://remote.rdsensing.com:36122');
    return list;
  }

  /// True when [baseUrl]'s host looks like a private LAN address (only
  /// reachable on the boat's own network). Used to pick timeouts and to
  /// decide whether a user-saved URL is local vs remote for failover.
  static bool isPrivateLanUrl(String baseUrl) {
    try {
      final host = Uri.parse(baseUrl).host.toLowerCase();
      if (host == 'localhost' || host == '127.0.0.1') return true;
      if (host.startsWith('10.')) return true;
      if (host.startsWith('192.168.')) return true;
      // 172.16.0.0 – 172.31.255.255
      final m = RegExp(r'^172\.(\d+)\.').firstMatch(host);
      if (m != null) {
        final second = int.tryParse(m.group(1)!);
        if (second != null && second >= 16 && second <= 31) return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  Duration _timeoutFor(String baseUrl) =>
      isPrivateLanUrl(baseUrl) ? _localTimeout : _remoteTimeout;

  /// Logs in at [baseUrl] directly with [username]/[password] — bypasses
  /// the WiFi-gating/candidate-ordering [checkConnection] normally applies,
  /// since this is for explicitly testing *one* address (the gateway setup
  /// screen's "Discover" and manual "Test" actions).
  ///
  /// Prefer [probeConnection] when the UI needs a friendly reason for
  /// failure; this bool wrapper stays for existing call sites.
  Future<bool> testConnection({
    required String baseUrl,
    required String username,
    required String password,
    http.Client? client,
  }) async {
    final result = await probeConnection(
      baseUrl: baseUrl,
      username: username,
      password: password,
      client: client,
    );
    return result.ok;
  }

  /// Like [testConnection] but returns a structured result so the setup
  /// screen can show "wrong password" vs "unreachable" vs "certificate".
  Future<GatewayProbeResult> probeConnection({
    required String baseUrl,
    required String username,
    required String password,
    http.Client? client,
  }) async {
    if (username.trim().isEmpty || password.isEmpty) {
      return const GatewayProbeResult(
        ok: false,
        detail: 'Enter username and password first.',
      );
    }
    final c = client ?? http.Client();
    try {
      final probe = PredictWindDatahubService(
        usernameOverride: username,
        passwordOverride: password,
      );
      final sysauth =
          await probe._login(c, baseUrl, _timeoutFor(baseUrl));
      if (sysauth != null) {
        return GatewayProbeResult(
          ok: true,
          detail: isPrivateLanUrl(baseUrl)
              ? 'Connected on the boat network.'
              : 'Connected via internet (remote access).',
        );
      }
      return const GatewayProbeResult(
        ok: false,
        detail: "Couldn't sign in — check username and password.",
      );
    } catch (e) {
      return GatewayProbeResult(
        ok: false,
        detail: friendlyConnectionError(e),
      );
    } finally {
      if (client == null) c.close();
    }
  }

  /// Tries every [knownLocalAddresses] entry concurrently (legacy name kept
  /// for tests). Prefer [discoverGateways] so internet tunnels are included.
  Future<List<String>> discoverLocalGateways({
    required String username,
    required String password,
    http.Client? client,
  }) async {
    final result = await discoverGateways(
      username: username,
      password: password,
      client: client,
      includeRemote: false,
    );
    return result.workingAddresses;
  }

  /// #263 follow-up — Discover for the gateway setup screen: probes known
  /// **local** addresses and (by default) PredictWind's **remote** tunnel
  /// URLs with [username]/[password], concurrently. Returns every address
  /// that accepted the login, plus a short human summary of what was tried.
  Future<GatewayDiscoveryResult> discoverGateways({
    required String username,
    required String password,
    http.Client? client,
    bool includeRemote = true,
  }) async {
    if (username.trim().isEmpty || password.isEmpty) {
      return const GatewayDiscoveryResult(
        workingAddresses: [],
        summary: 'Enter username and password before Discover.',
      );
    }

    final candidates = <String>[
      ...knownLocalAddresses,
      if (includeRemote) ...knownRemoteAddresses,
    ];
    // De-dupe while preserving order.
    final seen = <String>{};
    final unique = <String>[
      for (final a in candidates)
        if (seen.add(a)) a,
    ];

    final c = client ?? http.Client();
    try {
      final results = await Future.wait(unique.map(
        (address) => probeConnection(
          baseUrl: address,
          username: username,
          password: password,
          client: c,
        ),
      ));
      final working = <String>[
        for (var i = 0; i < unique.length; i++)
          if (results[i].ok) unique[i],
      ];
      final localHits =
          working.where(isPrivateLanUrl).toList(growable: false);
      final remoteHits =
          working.where((a) => !isPrivateLanUrl(a)).toList(growable: false);

      String summary;
      if (working.isEmpty) {
        // Surface the most useful failure from remote probes if any.
        String? remoteDetail;
        for (var i = 0; i < unique.length; i++) {
          if (!isPrivateLanUrl(unique[i]) && !results[i].ok) {
            remoteDetail = results[i].detail;
            break;
          }
        }
        summary = remoteDetail != null
            ? 'No gateway answered. Remote check: $remoteDetail '
                'Try again on boat WiFi for the local Hub, or enter the '
                'address manually and tap Test.'
            : 'No gateway answered among local and internet addresses. '
                'On the boat, join the boat WiFi and try again; off the boat, '
                'confirm the Hub remote-access tunnel is online.';
      } else if (localHits.isNotEmpty && remoteHits.isNotEmpty) {
        summary =
            'Found ${working.length}: ${localHits.length} on boat WiFi, '
            '${remoteHits.length} via internet.';
      } else if (localHits.isNotEmpty) {
        summary =
            'Found ${localHits.length} on the boat network (local WiFi).';
      } else {
        summary =
            'Found ${remoteHits.length} via internet (remote access) — '
            'usable away from the boat.';
      }

      return GatewayDiscoveryResult(
        workingAddresses: working,
        summary: summary,
      );
    } finally {
      if (client == null) c.close();
    }
  }

  double? _asDouble(dynamic v) => v is num ? v.toDouble() : null;
}

/// Result of probing a single Hub base URL (setup screen Test / Discover).
class GatewayProbeResult {
  final bool ok;
  final String? detail;
  const GatewayProbeResult({required this.ok, this.detail});
}

/// Result of [PredictWindDatahubService.discoverGateways].
class GatewayDiscoveryResult {
  final List<String> workingAddresses;
  final String summary;
  const GatewayDiscoveryResult({
    required this.workingAddresses,
    required this.summary,
  });
}

class _Candidate {
  final String baseUrl;
  final bool isLocal;
  final Duration timeout;
  const _Candidate(this.baseUrl, {required this.isLocal, required this.timeout});
}
