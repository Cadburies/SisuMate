import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:http/http.dart' as http;

import '../models/models.dart';
import 'home_assistant_service.dart';
import 'predictwind_datahub_service.dart';
import 'ydwg_nmea_service.dart';

/// #263 — which path produced the active boat instrument reading.
enum BoatInstrumentSource {
  dataHubLocal,
  ydwgNmeaLocal,
  homeAssistantLocal,
  dataHubRemote,
  homeAssistantRemote,
}

extension BoatInstrumentSourceLabel on BoatInstrumentSource {
  String get label => switch (this) {
        BoatInstrumentSource.dataHubLocal => 'DataHub (local)',
        BoatInstrumentSource.ydwgNmeaLocal => 'YDWG-02 (NMEA local)',
        BoatInstrumentSource.homeAssistantLocal => 'Home Assistant (local)',
        BoatInstrumentSource.dataHubRemote => 'DataHub (internet)',
        BoatInstrumentSource.homeAssistantRemote =>
          'Home Assistant (internet)',
      };

  bool get isLocal => switch (this) {
        BoatInstrumentSource.dataHubLocal ||
        BoatInstrumentSource.ydwgNmeaLocal ||
        BoatInstrumentSource.homeAssistantLocal =>
          true,
        _ => false,
      };
}

/// Result of a multi-source instrument fetch for Anchor Alarm.
class BoatInstrumentSnapshot {
  final PredictWindBoatData? boatData;
  final BoatInstrumentSource? activeSource;
  final PredictWindHubStatus hubStatus;
  final List<String> tried;
  final List<String> failures;

  const BoatInstrumentSnapshot({
    required this.boatData,
    required this.activeSource,
    required this.hubStatus,
    this.tried = const [],
    this.failures = const [],
  });

  bool get hasFix => boatData?.hasFix ?? false;

  String get summary {
    if (activeSource != null && boatData != null) {
      final fix = boatData!.hasFix ? 'GPS fix' : 'connected, no GPS fix yet';
      return '${activeSource!.label}: $fix';
    }
    if (failures.isEmpty) {
      return hubStatus.detail ?? 'No instrument source configured.';
    }
    return 'No source answered. ${failures.join(' · ')}';
  }
}

/// #263 — multi-source boat instrument failover for Anchor Alarm.
///
/// **Order (local first — lower latency on the boat network, then internet
/// for beach-bar / cellular when the boat is dragging).** DataHub and Home
/// Assistant are peers — each has a **local** and an **internet** path:
///
/// 1. **DataHub local** (boat WiFi / IoT LAN) — WiFi-gated.
/// 2. **YDWG-02 NMEA local** (TCP, default port 1456) — WiFi-gated.
/// 3. **Home Assistant local** — WiFi-gated (boat LAN HA).
/// 4. **DataHub internet** (`remote.rdsensing.com`) — beach-bar path.
/// 5. **Home Assistant internet** (Nabu Casa / reverse proxy).
///
/// First source that returns a usable [PredictWindBoatData] with a GPS fix
/// wins. If a source connects but has no fix, the next source is still tried.
class BoatInstrumentFailoverService {
  const BoatInstrumentFailoverService({
    this.connectivityOverride,
  });

  final Connectivity? connectivityOverride;

  Future<bool> _onWifi() async {
    try {
      final results = await (connectivityOverride ?? Connectivity())
          .checkConnectivity()
          // Short bound: missing-plugin / test envs hang otherwise, and
          // Anchor Alarm refresh must not stall the UI for seconds.
          .timeout(const Duration(milliseconds: 250));
      return results.contains(ConnectivityResult.wifi);
    } catch (_) {
      // Missing plugin / test binding: try local candidates first (short
      // timeouts) so boat WiFi isn't skipped blindly.
      return true;
    }
  }

  /// Build the ordered candidate list for tests / UI explanation.
  Future<List<BoatInstrumentSource>> plannedSources({
    required UserSettings? settings,
    PredictWindDatahubService? hubService,
  }) async {
    final onWifi = await _onWifi();
    final hub = hubService ?? _hubFromSettings(settings);
    final haLocal = _haLocal(settings);
    final haRemote = _haRemote(settings);

    final list = <BoatInstrumentSource>[];
    if (onWifi && hub.isConfigured) {
      // Local only meaningful if a local URL is present or dart-define local.
      list.add(BoatInstrumentSource.dataHubLocal);
    }
    if (onWifi && _ydwgHost(settings) != null) {
      list.add(BoatInstrumentSource.ydwgNmeaLocal);
    }
    if (onWifi && haLocal.isConfigured && haLocal.hasGpsConfig) {
      list.add(BoatInstrumentSource.homeAssistantLocal);
    }
    if (hub.isConfigured) {
      list.add(BoatInstrumentSource.dataHubRemote);
    }
    if (haRemote.isConfigured && haRemote.hasGpsConfig) {
      list.add(BoatInstrumentSource.homeAssistantRemote);
    }
    return list;
  }

  Future<BoatInstrumentSnapshot> fetch({
    required UserSettings? settings,
    PredictWindDatahubService? hubService,
    http.Client? client,
  }) async {
    final hub = hubService ?? _hubFromSettings(settings);
    final haLocal = _haLocal(settings);
    final haRemote = _haRemote(settings);
    final onWifi = await _onWifi();

    final tried = <String>[];
    final failures = <String>[];
    // Best connected-but-no-fix reading (stale / quality 0) for UI messaging.
    PredictWindBoatData? softData;
    BoatInstrumentSource? softSource;

    void keepSoft(PredictWindBoatData data, BoatInstrumentSource src) {
      softData ??= data;
      softSource ??= src;
    }

    // --- Local band (WiFi only) ---
    if (onWifi) {
      if (hub.isConfigured && hub.hasCredentials) {
        tried.add(BoatInstrumentSource.dataHubLocal.label);
        final data = await hub.fetchBoatData(client: client);
        if (data != null && data.viaLocalNetwork) {
          final labeled = data.copyWith(
            sourceLabel: BoatInstrumentSource.dataHubLocal.label,
          );
          if (labeled.hasFix) {
            return BoatInstrumentSnapshot(
              boatData: labeled,
              activeSource: BoatInstrumentSource.dataHubLocal,
              hubStatus: PredictWindHubStatus(
                PredictWindHubConnectionState.connected,
                viaLocalNetwork: true,
                detail: labeled.sourceLabel,
              ),
              tried: tried,
              failures: failures,
            );
          }
          keepSoft(labeled, BoatInstrumentSource.dataHubLocal);
          failures.add('DataHub local: no GPS fix');
        } else if (data != null && !data.viaLocalNetwork) {
          // Got remote while probing; soft-hold and continue internet band.
          keepSoft(
            data.copyWith(sourceLabel: BoatInstrumentSource.dataHubRemote.label),
            BoatInstrumentSource.dataHubRemote,
          );
        } else {
          failures.add('DataHub local: no data');
        }
      }

      // YDWG NMEA 0183 over TCP (default 1456) — after DataHub local.
      final ydwgHost = _ydwgHost(settings);
      if (ydwgHost != null) {
        tried.add(BoatInstrumentSource.ydwgNmeaLocal.label);
        final ydwg = YdwgNmeaService(
          host: ydwgHost,
          port: _ydwgPort(settings),
        );
        final data = await ydwg.fetchBoatData();
        if (data != null && data.hasFix) {
          return BoatInstrumentSnapshot(
            boatData: data,
            activeSource: BoatInstrumentSource.ydwgNmeaLocal,
            hubStatus: PredictWindHubStatus(
              PredictWindHubConnectionState.connected,
              viaLocalNetwork: true,
              detail: data.sourceLabel,
            ),
            tried: tried,
            failures: failures,
          );
        }
        if (data != null) {
          keepSoft(data, BoatInstrumentSource.ydwgNmeaLocal);
          failures.add('YDWG NMEA: no GPS fix yet');
        } else {
          failures.add('YDWG NMEA: no data on port ${_ydwgPort(settings)}');
        }
      }

      if (haLocal.isConfigured && haLocal.hasGpsConfig) {
        tried.add(BoatInstrumentSource.homeAssistantLocal.label);
        final probe = await haLocal.probeConnection(client: client);
        if (!probe.ok) {
          failures.add('HA local: ${probe.detail ?? "unreachable"}');
        } else {
          final data = await haLocal.fetchBoatData(
            client: client,
            viaLocalNetwork: true,
            sourceLabel: BoatInstrumentSource.homeAssistantLocal.label,
          );
          if (data != null && data.hasFix) {
            return BoatInstrumentSnapshot(
              boatData: data,
              activeSource: BoatInstrumentSource.homeAssistantLocal,
              hubStatus: PredictWindHubStatus(
                PredictWindHubConnectionState.connected,
                viaLocalNetwork: true,
                detail: data.sourceLabel,
              ),
              tried: tried,
              failures: failures,
            );
          }
          if (data != null) {
            keepSoft(data, BoatInstrumentSource.homeAssistantLocal);
          }
          failures.add('HA local: ${data == null ? "no data" : "no GPS fix"}');
        }
      }
    }

    // --- Internet band (always) ---
    if (hub.isConfigured && hub.hasCredentials) {
      tried.add(BoatInstrumentSource.dataHubRemote.label);
      final data = await hub.fetchBoatData(client: client);
      if (data != null) {
        final src = data.viaLocalNetwork
            ? BoatInstrumentSource.dataHubLocal
            : BoatInstrumentSource.dataHubRemote;
        final labeled = data.copyWith(sourceLabel: src.label);
        if (labeled.hasFix) {
          return BoatInstrumentSnapshot(
            boatData: labeled,
            activeSource: src,
            hubStatus: PredictWindHubStatus(
              PredictWindHubConnectionState.connected,
              viaLocalNetwork: labeled.viaLocalNetwork,
              detail: labeled.sourceLabel,
            ),
            tried: tried,
            failures: failures,
          );
        }
        keepSoft(labeled, src);
        failures.add('DataHub: connected, no GPS fix');
      } else {
        final st = await hub.checkConnection(client: client);
        failures.add('DataHub: ${st.detail ?? st.state.name}');
      }
    } else if (hub.isConfigured && !hub.hasCredentials) {
      failures.add('DataHub: missing login');
    }

    if (haRemote.isConfigured && haRemote.hasGpsConfig) {
      tried.add(BoatInstrumentSource.homeAssistantRemote.label);
      final probe = await haRemote.probeConnection(client: client);
      if (!probe.ok) {
        failures.add('HA internet: ${probe.detail ?? "unreachable"}');
      } else {
        final data = await haRemote.fetchBoatData(
          client: client,
          viaLocalNetwork: false,
          sourceLabel: BoatInstrumentSource.homeAssistantRemote.label,
        );
        if (data != null && data.hasFix) {
          return BoatInstrumentSnapshot(
            boatData: data,
            activeSource: BoatInstrumentSource.homeAssistantRemote,
            hubStatus: PredictWindHubStatus(
              PredictWindHubConnectionState.connected,
              viaLocalNetwork: false,
              detail: data.sourceLabel,
            ),
            tried: tried,
            failures: failures,
          );
        }
        if (data != null) {
          keepSoft(data, BoatInstrumentSource.homeAssistantRemote);
        }
        failures.add(
            'HA internet: ${data == null ? "no data" : "no GPS fix"}');
      }
    }

    // Soft result: connected somewhere but no fresh GPS fix (stale / quality 0).
    if (softData != null) {
      return BoatInstrumentSnapshot(
        boatData: softData,
        activeSource: softSource,
        hubStatus: PredictWindHubStatus(
          PredictWindHubConnectionState.connected,
          viaLocalNetwork: softData!.viaLocalNetwork,
          detail: softData!.sourceLabel ?? softSource?.label,
        ),
        tried: tried,
        failures: failures,
      );
    }

    final hubStatus = await _finalStatus(
      hub: hub,
      failures: failures,
      client: client,
    );

    return BoatInstrumentSnapshot(
      boatData: null,
      activeSource: null,
      hubStatus: hubStatus,
      tried: tried,
      failures: failures,
    );
  }

  Future<PredictWindHubStatus> _finalStatus({
    required PredictWindDatahubService hub,
    required List<String> failures,
    http.Client? client,
  }) async {
    if (!hub.isConfigured && failures.isEmpty) {
      return const PredictWindHubStatus(
        PredictWindHubConnectionState.notConfigured,
        detail: 'Configure DataHub and/or Home Assistant in Gateway Setup.',
      );
    }
    if (hub.isConfigured && !hub.hasCredentials) {
      return const PredictWindHubStatus(
        PredictWindHubConnectionState.missingCredentials,
      );
    }
    if (hub.isConfigured) {
      final st = await hub.checkConnection(client: client);
      if (st.state == PredictWindHubConnectionState.connected) {
        return PredictWindHubStatus(
          PredictWindHubConnectionState.connected,
          viaLocalNetwork: st.viaLocalNetwork,
          detail: 'Connected but no GPS fix from any source. '
              '${failures.isNotEmpty ? failures.join(' · ') : ''}',
        );
      }
      return PredictWindHubStatus(
        st.state,
        detail: failures.isNotEmpty
            ? failures.join(' · ')
            : st.detail,
      );
    }
    return PredictWindHubStatus(
      PredictWindHubConnectionState.unreachable,
      detail: failures.isNotEmpty
          ? failures.join(' · ')
          : 'No instrument source available.',
    );
  }

  PredictWindDatahubService _hubFromSettings(UserSettings? settings) {
    if (settings == null) return const PredictWindDatahubService();
    final savedUrl = settings.predictwindHubLocalUrl.trim();
    final user = settings.predictwindHubUsername.isNotEmpty
        ? settings.predictwindHubUsername
        : null;
    final pass = settings.predictwindHubPassword.isNotEmpty
        ? settings.predictwindHubPassword
        : null;
    if (savedUrl.isEmpty && user == null && pass == null) {
      return const PredictWindDatahubService();
    }
    final isLan = savedUrl.isNotEmpty &&
        PredictWindDatahubService.isPrivateLanUrl(savedUrl);
    return PredictWindDatahubService(
      localBaseUrlOverride: isLan ? savedUrl : null,
      baseUrlOverride: !isLan && savedUrl.isNotEmpty ? savedUrl : null,
      usernameOverride: user,
      passwordOverride: pass,
    );
  }

  HomeAssistantService _haLocal(UserSettings? s) =>
      HomeAssistantService.localFromSettings(
        settingsUrl: s?.homeAssistantUrl,
        settingsToken: s?.homeAssistantToken,
        gpsEntity: s?.homeAssistantGpsEntity,
        latEntity: s?.homeAssistantLatEntity,
        lonEntity: s?.homeAssistantLonEntity,
        windSpeedEntity: s?.homeAssistantWindSpeedEntity,
        windDirEntity: s?.homeAssistantWindDirEntity,
        depthEntity: s?.homeAssistantDepthEntity,
      );

  HomeAssistantService _haRemote(UserSettings? s) =>
      HomeAssistantService.remoteFromSettings(
        settingsRemoteUrl: s?.homeAssistantRemoteUrl,
        settingsToken: s?.homeAssistantToken,
        gpsEntity: s?.homeAssistantGpsEntity,
        latEntity: s?.homeAssistantLatEntity,
        lonEntity: s?.homeAssistantLonEntity,
        windSpeedEntity: s?.homeAssistantWindSpeedEntity,
        windDirEntity: s?.homeAssistantWindDirEntity,
        depthEntity: s?.homeAssistantDepthEntity,
      );

  /// Only when the user has saved a YDWG URL (Gateway Setup) — do not
  /// auto-probe the factory default IP (would hang tests / off-boat phones
  /// on an unreachable LAN address for the full NMEA listen window).
  String? _ydwgHost(UserSettings? s) {
    final raw = s?.ydwgUrl.trim() ?? '';
    if (raw.isEmpty) return null;
    return YdwgNmeaService.hostFromUrl(raw);
  }

  int _ydwgPort(UserSettings? s) {
    // Optional `:port` on ydwgUrl host is not used for HTTP UI; NMEA port is
    // independent (YDWG factory default 1456).
    return YdwgNmeaService.defaultPortResolved;
  }
}
