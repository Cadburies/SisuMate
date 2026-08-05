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
/// YDWG-02 on the same IoT VLAN sits at `192.168.10.30` (`YDWGIP` /
/// [defaultYdwgUrl]) — raw NMEA gateway, not LuCI; Discover only pings
/// reachability. Full NMEA parse is still deferred (#263).
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
  /// #266 — speed over ground (kn) from Hub `sog`.
  final double? sogKt;
  /// #266 — course over ground (°) from Hub `cog`.
  final double? cogDeg;
  /// #266 — apparent wind speed (kn) from Hub `aws`.
  final double? apparentWindSpeedKt;
  /// #266 — apparent wind angle/direction (°) from Hub `awa`.
  final double? apparentWindDirectionDeg;
  /// #263 — true when this reading came from the boat's local WiFi rather
  /// than the internet/remote-access tunnel.
  final bool viaLocalNetwork;
  /// #263 — human label for the winning failover source
  /// (e.g. `DataHub (local)`, `Home Assistant (internet)`).
  final String? sourceLabel;
  final DateTime observedAt;
  const PredictWindBoatData({
    this.latitude,
    this.longitude,
    this.windSpeedKt,
    this.windDirectionDeg,
    this.depthMeters,
    this.sogKt,
    this.cogDeg,
    this.apparentWindSpeedKt,
    this.apparentWindDirectionDeg,
    this.viaLocalNetwork = false,
    this.sourceLabel,
    required this.observedAt,
  });

  PredictWindBoatData copyWith({
    double? latitude,
    double? longitude,
    double? windSpeedKt,
    double? windDirectionDeg,
    double? depthMeters,
    double? sogKt,
    double? cogDeg,
    double? apparentWindSpeedKt,
    double? apparentWindDirectionDeg,
    bool? viaLocalNetwork,
    String? sourceLabel,
    DateTime? observedAt,
  }) =>
      PredictWindBoatData(
        latitude: latitude ?? this.latitude,
        longitude: longitude ?? this.longitude,
        windSpeedKt: windSpeedKt ?? this.windSpeedKt,
        windDirectionDeg: windDirectionDeg ?? this.windDirectionDeg,
        depthMeters: depthMeters ?? this.depthMeters,
        sogKt: sogKt ?? this.sogKt,
        cogDeg: cogDeg ?? this.cogDeg,
        apparentWindSpeedKt: apparentWindSpeedKt ?? this.apparentWindSpeedKt,
        apparentWindDirectionDeg:
            apparentWindDirectionDeg ?? this.apparentWindDirectionDeg,
        viaLocalNetwork: viaLocalNetwork ?? this.viaLocalNetwork,
        sourceLabel: sourceLabel ?? this.sourceLabel,
        observedAt: observedAt ?? this.observedAt,
      );

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
  /// Optional bare IP for the PredictWind DataHub on the boat LAN
  /// (`DATAHUBIP` in dart-defines / .env), e.g. `192.168.10.31`.
  static const _dataHubIp = String.fromEnvironment('DATAHUBIP');
  /// Optional bare IP for a Yacht Devices YDWG-02 on the boat LAN
  /// (`YDWGIP` in dart-defines / .env), e.g. `192.168.10.30`.
  static const _ydwgIp = String.fromEnvironment('YDWGIP');
  /// Optional full base URL for the YDWG (`YDWG_URL`), e.g.
  /// `http://192.168.10.30`. Wins over [\_ydwgIp] when set.
  static const _ydwgUrlEnv = String.fromEnvironment('YDWG_URL');
  static const _ydwgUsernameEnv =
      String.fromEnvironment('YDWG_USERNAME');
  static const _ydwgPasswordEnv =
      String.fromEnvironment('YDWG_PASSWORD');
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

  /// Prefer http — HTTPS on the vendor tunnel is often self-signed (#257/#260).
  static const defaultDataHubRemoteUrl = 'http://remote.rdsensing.com:36121';

  /// Boat-LAN DataHub default when no dart-define is set (this boat's IoT VLAN).
  static const _fallbackDataHubLocalUrl = 'http://192.168.10.31';

  /// Boat-LAN YDWG-02 default when `YDWGIP` / `YDWG_URL` are unset.
  static const _fallbackYdwgIp = '192.168.10.30';

  /// Factory web-UI credentials for YDWG-02 (admin / admin).
  static const defaultYdwgUsername = 'admin';
  static const defaultYdwgPassword = 'admin';

  /// Normalize a bare IP or host into an `http://…` base URL.
  static String _asHttpBase(String raw) {
    final t = raw.trim();
    if (t.isEmpty) return t;
    if (t.startsWith('http://') || t.startsWith('https://')) return t;
    return 'http://$t';
  }

  /// DataHub on the boat network — from `PREDICTWIND_HUB_LOCAL_URL` or
  /// `DATAHUBIP`, else [\_fallbackDataHubLocalUrl].
  static String get defaultDataHubLocalUrl {
    if (_hubLocalUrl.isNotEmpty) return _asHttpBase(_hubLocalUrl);
    if (_dataHubIp.isNotEmpty) return _asHttpBase(_dataHubIp);
    return _fallbackDataHubLocalUrl;
  }

  /// Yacht Devices YDWG-02 on the boat network — from `YDWG_URL` or
  /// `YDWGIP`, else [\_fallbackYdwgIp]. Web UI at `/home.html` (login
  /// `POST /login?login=&password=` → session cookie). NMEA data ports
  /// are separate; this URL is for config + login probe.
  static String get defaultYdwgUrl {
    if (_ydwgUrlEnv.isNotEmpty) return _asHttpBase(_ydwgUrlEnv);
    if (_ydwgIp.isNotEmpty) return _asHttpBase(_ydwgIp);
    return _asHttpBase(_fallbackYdwgIp);
  }

  /// YDWG web login — dart-define when set, else factory `admin`.
  static String get defaultYdwgUsernameResolved =>
      _ydwgUsernameEnv.isNotEmpty ? _ydwgUsernameEnv : defaultYdwgUsername;

  /// YDWG web password — dart-define when set, else factory `admin`.
  static String get defaultYdwgPasswordResolved =>
      _ydwgPasswordEnv.isNotEmpty ? _ydwgPasswordEnv : defaultYdwgPassword;

  /// Internet DataHub tunnel — dart-define HTTP first, else vendor default.
  static String get defaultDataHubRemoteUrlResolved {
    if (_hubHttpUrl.isNotEmpty) return _asHttpBase(_hubHttpUrl);
    return defaultDataHubRemoteUrl;
  }

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
            sogKt: _asDouble(json['sog']),
            cogDeg: _asDouble(json['cog']),
            apparentWindSpeedKt: _asDouble(json['aws']),
            apparentWindDirectionDeg: _asDouble(json['awa']),
            viaLocalNetwork: candidate.isLocal,
            sourceLabel: candidate.isLocal
                ? 'DataHub (local)'
                : 'DataHub (internet)',
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

  /// #263 — **local-WiFi LuCI** DataHub addresses tried by Discover login.
  /// Order: this boat's default → PredictWind stock default. YDWG-02 is
  /// *not* here (no LuCI); see [defaultYdwgUrl] / reachability probe.
  static List<String> get knownLocalAddresses {
    final list = <String>[];
    void add(String url) {
      final u = _asHttpBase(url);
      if (u.isNotEmpty && !list.contains(u)) list.add(u);
    }

    add(defaultDataHubLocalUrl);
    add('http://10.10.10.1');
    return list;
  }

  /// #263 follow-up — PredictWind / RDS **internet tunnel** base URLs tried
  /// by Discover when you're not on the boat WiFi (beach bar, marina cafe).
  /// HTTP first: the HTTPS endpoint uses a self-signed cert that dart:io
  /// rejects (#257/#260). Compile-time dart-defines are preferred when set;
  /// the vendor hostnames are always included as a fallback.
  static List<String> get knownRemoteAddresses {
    final list = <String>[];
    void add(String? url) {
      if (url == null || url.isEmpty) return;
      final u = _asHttpBase(url);
      if (!list.contains(u)) list.add(u);
    }

    add(defaultDataHubRemoteUrlResolved);
    add(_hubUrl.isNotEmpty ? _hubUrl : null);
    add(defaultDataHubRemoteUrl);
    add('https://remote.rdsensing.com:36122');
    return list;
  }

  /// Suggested boat-LAN endpoints shown in gateway setup (quick-pick chips).
  /// Includes DataHub local + YDWG-02 even when Discover hasn't run.
  static List<GatewayDefaultSuggestion> get boatLanDefaults => [
        GatewayDefaultSuggestion(
          url: defaultDataHubLocalUrl,
          label: 'DataHub local',
          tip: 'Default for DataHub on boat WiFi / intranet',
          kind: GatewayDefaultKind.dataHubLocal,
        ),
        GatewayDefaultSuggestion(
          url: defaultYdwgUrl,
          label: 'YDWG-02',
          tip: 'Default for YDWG-02 (NMEA gateway, no Hub login)',
          kind: GatewayDefaultKind.ydwg,
        ),
      ];

  /// Internet DataHub default for the address field / chips.
  static List<GatewayDefaultSuggestion> get internetDefaults => [
        GatewayDefaultSuggestion(
          url: defaultDataHubRemoteUrlResolved,
          label: 'DataHub internet',
          tip: 'Default for DataHub',
          kind: GatewayDefaultKind.dataHubRemote,
        ),
      ];

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
  /// **local** DataHub addresses and (by default) PredictWind **remote**
  /// tunnel URLs with [username]/[password] (LuCI login). Also pings the
  /// YDWG-02 host for reachability (no login — raw NMEA device).
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

      // YDWG-02: no LuCI — reachability only; never mixed into Hub login hits
      // (saving it as predictwindHubLocalUrl would break the Hub path).
      final ydwgUp =
          await probeHostReachable(defaultYdwgUrl, client: c);

      final localHits =
          working.where(isPrivateLanUrl).toList(growable: false);
      final remoteHits =
          working.where((a) => !isPrivateLanUrl(a)).toList(growable: false);
      final ydwgNote = ydwgUp
          ? ' YDWG-02 host reachable at $defaultYdwgUrl (NMEA — not Hub login).'
          : '';

      String summary;
      if (working.isEmpty) {
        String? remoteDetail;
        for (var i = 0; i < unique.length; i++) {
          if (!isPrivateLanUrl(unique[i]) && !results[i].ok) {
            remoteDetail = results[i].detail;
            break;
          }
        }
        if (ydwgUp) {
          summary =
              'No DataHub login answered, but YDWG-02 is reachable at '
              '$defaultYdwgUrl (raw NMEA — use a DataHub address for Hub Save).';
        } else if (remoteDetail != null) {
          summary =
              'No gateway answered. Remote check: $remoteDetail '
              'Try again on boat WiFi for the local Hub, or enter the '
              'address manually and tap Test.';
        } else {
          summary =
              'No gateway answered among local and internet addresses. '
              'On the boat, join the boat WiFi and try again; off the boat, '
              'confirm the Hub remote-access tunnel is online.';
        }
      } else if (localHits.isNotEmpty && remoteHits.isNotEmpty) {
        summary =
            'Found ${working.length}: ${localHits.length} on boat WiFi, '
            '${remoteHits.length} via internet.$ydwgNote';
      } else if (localHits.isNotEmpty) {
        summary =
            'Found ${localHits.length} on the boat network (local WiFi).'
            '$ydwgNote';
      } else {
        summary =
            'Found ${remoteHits.length} via internet (remote access) — '
            'usable away from the boat.$ydwgNote';
      }

      return GatewayDiscoveryResult(
        workingAddresses: working,
        summary: summary,
        ydwgReachable: ydwgUp,
      );
    } finally {
      if (client == null) c.close();
    }
  }

  /// Lightweight "is anything listening?" check for non-LuCI devices
  /// (YDWG-02). Any HTTP response (including 404) counts as reachable;
  /// timeouts / connection refused do not.
  Future<bool> probeHostReachable(
    String baseUrl, {
    http.Client? client,
  }) async {
    final c = client ?? http.Client();
    try {
      final res = await c
          .get(Uri.parse(baseUrl))
          .timeout(_timeoutFor(baseUrl));
      // Any status means the host answered on that port.
      return res.statusCode > 0;
    } catch (_) {
      return false;
    } finally {
      if (client == null) c.close();
    }
  }

  /// YDWG-02 web UI login (live-verified):
  /// `POST /login?1=1&login=…&password=…` → `204` + `Set-Cookie: session=…`
  /// on success; `500` body "Failed to authenticate" on bad credentials.
  /// [baseUrl] is the device root (`http://192.168.10.30`), not `/home.html`.
  Future<GatewayProbeResult> probeYdwgLogin({
    required String baseUrl,
    required String username,
    required String password,
    http.Client? client,
  }) async {
    final base = _asHttpBase(baseUrl);
    if (base.isEmpty) {
      return const GatewayProbeResult(
        ok: false,
        detail: 'Enter a YDWG address first.',
      );
    }
    if (username.trim().isEmpty || password.isEmpty) {
      return const GatewayProbeResult(
        ok: false,
        detail: 'Enter YDWG username and password.',
      );
    }
    final c = client ?? http.Client();
    try {
      final uri = Uri.parse(base).replace(
        path: '/login',
        queryParameters: {
          '1': '1',
          'login': username.trim().toLowerCase(),
          'password': password,
        },
      );
      final res = await c.post(uri).timeout(_timeoutFor(base));
      if (res.statusCode == 204 || res.statusCode == 200) {
        final setCookie = res.headers['set-cookie'] ?? '';
        if (setCookie.toLowerCase().contains('session=') ||
            res.statusCode == 204) {
          return GatewayProbeResult(
            ok: true,
            detail: 'Signed in to YDWG at $base.',
          );
        }
      }
      if (res.statusCode == 500 ||
          res.body.toLowerCase().contains('failed to authenticate') ||
          res.body.toLowerCase().contains('invalid')) {
        return const GatewayProbeResult(
          ok: false,
          detail: "Couldn't sign in to YDWG — check username and password.",
        );
      }
      return GatewayProbeResult(
        ok: false,
        detail:
            "YDWG answered but login didn't succeed (HTTP ${res.statusCode}).",
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
  final bool ydwgReachable;
  const GatewayDiscoveryResult({
    required this.workingAddresses,
    required this.summary,
    this.ydwgReachable = false,
  });
}

enum GatewayDefaultKind { dataHubRemote, dataHubLocal, ydwg }

/// Quick-pick default shown on the gateway setup screen.
class GatewayDefaultSuggestion {
  final String url;
  final String label;
  final String tip;
  final GatewayDefaultKind kind;
  const GatewayDefaultSuggestion({
    required this.url,
    required this.label,
    required this.tip,
    required this.kind,
  });
}

class _Candidate {
  final String baseUrl;
  final bool isLocal;
  final Duration timeout;
  const _Candidate(this.baseUrl, {required this.isLocal, required this.timeout});
}
