import 'dart:async';

import 'package:http/http.dart' as http;

import 'error_log_service.dart';

/// #256 — connectivity layer for a PredictWind Datahub ("PW-Hub") reachable
/// via a remote-access tunnel (`remote.rdsensing.com`, dart-defines
/// `PREDICTWIND_HUB_URL` / `PREDICTWIND_HUB_HTTP_URL`).
///
/// Live-verified against the real endpoints (2026-08-04): both URLs serve
/// the Hub's OpenWrt/LuCI admin interface (`/cgi-bin/luci/` responds
/// `403` with header `X-LuCI-Login-Required: yes`) — not a data API. No
/// unauthenticated SignalK/NMEA path is proxied through the same tunnel
/// (`/signalk`, `/signalk/v1/api/vessels/self` both `404`). [fetchBoatData]
/// therefore has no live data source yet and always returns null until
/// LuCI credentials or a confirmed data endpoint are available — kept as a
/// real, testable seam so wiring up a confirmed source later doesn't touch
/// call sites.
enum PredictWindHubConnectionState {
  notConfigured,
  reachable,
  reachableAuthRequired,
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
  final DateTime observedAt;
  const PredictWindBoatData({
    this.latitude,
    this.longitude,
    this.windSpeedKt,
    this.windDirectionDeg,
    required this.observedAt,
  });
}

class PredictWindDatahubService {
  /// [baseUrlOverride] is a test-only seam — the real base URL is normally
  /// baked in at compile time via `String.fromEnvironment`, which can't be
  /// overridden at `flutter test` runtime the way `--dart-define` sets it
  /// for a real build.
  const PredictWindDatahubService({String? baseUrlOverride})
      : _baseUrlOverride = baseUrlOverride;

  final String? _baseUrlOverride;

  static const _hubUrl = String.fromEnvironment('PREDICTWIND_HUB_URL');
  static const _hubHttpUrl =
      String.fromEnvironment('PREDICTWIND_HUB_HTTP_URL');
  static const _timeout = Duration(seconds: 8);
  static const _probePath = 'cgi-bin/luci/';

  String? get _baseUrl =>
      _baseUrlOverride ??
      (_hubUrl.isNotEmpty
          ? _hubUrl
          : (_hubHttpUrl.isNotEmpty ? _hubHttpUrl : null));

  bool get isConfigured => _baseUrl != null;

  Future<PredictWindHubStatus> checkConnection({http.Client? client}) async {
    final base = _baseUrl;
    if (base == null) {
      return const PredictWindHubStatus(
          PredictWindHubConnectionState.notConfigured);
    }
    final c = client ?? http.Client();
    try {
      final res =
          await c.get(Uri.parse('$base/$_probePath')).timeout(_timeout);
      if (res.headers['x-luci-login-required'] == 'yes' ||
          res.statusCode == 403) {
        return PredictWindHubStatus(
          PredictWindHubConnectionState.reachableAuthRequired,
          detail: 'HTTP ${res.statusCode}',
        );
      }
      if (res.statusCode >= 200 && res.statusCode < 400) {
        return PredictWindHubStatus(
          PredictWindHubConnectionState.reachable,
          detail: 'HTTP ${res.statusCode}',
        );
      }
      return PredictWindHubStatus(
        PredictWindHubConnectionState.unreachable,
        detail: 'HTTP ${res.statusCode}',
      );
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

  /// See class doc — no confirmed unauthenticated data endpoint exists yet.
  Future<PredictWindBoatData?> fetchBoatData({http.Client? client}) async {
    return null;
  }
}
