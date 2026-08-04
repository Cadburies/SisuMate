import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../components/title_tile.dart';
import '../components/common_drawer.dart';
import '../../services/location_service.dart';
import '../../services/predictwind_datahub_service.dart';

/// #256 — first cut of the Anchor Alarm module: connects to a configured
/// PredictWind Datahub (if any) and shows what's actually reachable today.
/// Anchor set/edit, the chain-scope geofence circle, and the wind-swing
/// danger-zone sector are tracked separately in that issue, not here yet.
class AnchorAlarmScreen extends ConsumerStatefulWidget {
  const AnchorAlarmScreen({
    super.key,
    this.locationService = const LocationService(),
    this.hubService = const PredictWindDatahubService(),
    this.httpClient,
  });

  final LocationService locationService;
  final PredictWindDatahubService hubService;
  final http.Client? httpClient;

  @override
  ConsumerState<AnchorAlarmScreen> createState() => _AnchorAlarmScreenState();
}

class _AnchorAlarmScreenState extends ConsumerState<AnchorAlarmScreen> {
  bool _loading = true;
  PredictWindHubStatus? _hubStatus;
  PredictWindBoatData? _boatData;
  LocationResult? _phoneLocation;

  @override
  void initState() {
    super.initState();
    unawaited(_refresh());
  }

  Future<void> _refresh() async {
    setState(() => _loading = true);
    final hubStatus =
        await widget.hubService.checkConnection(client: widget.httpClient);
    final boatData =
        await widget.hubService.fetchBoatData(client: widget.httpClient);
    LocationResult? phoneLocation;
    if (boatData?.latitude == null) {
      phoneLocation = await widget.locationService.getCurrentPosition();
    }
    if (!mounted) return;
    setState(() {
      _hubStatus = hubStatus;
      _boatData = boatData;
      _phoneLocation = phoneLocation;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Builder(
          builder: (context) => Column(
            children: [
              TitleTile(
                title: 'Anchor Alarm',
                onMenuPressed: () => Scaffold.of(context).openEndDrawer(),
              ),
              Expanded(
                child: _loading
                    ? const Center(child: CircularProgressIndicator())
                    : RefreshIndicator(
                        onRefresh: _refresh,
                        child: ListView(
                          padding: const EdgeInsets.all(12),
                          children: [
                            _HubStatusCard(
                                status: _hubStatus, onRefresh: _refresh),
                            const SizedBox(height: 12),
                            _PositionCard(
                              boatData: _boatData,
                              phoneLocation: _phoneLocation,
                            ),
                            const SizedBox(height: 12),
                            _WindCard(boatData: _boatData),
                            const SizedBox(height: 12),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 4),
                              child: Text(
                                'Anchor set/edit, the chain-scope geofence '
                                'circle, and a wind-swing danger zone are '
                                'tracked separately — see issue #256.',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ),
                          ],
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
      endDrawer: _buildEndDrawer(),
    );
  }

  Widget _buildEndDrawer() {
    return Drawer(
      child: SafeArea(
        child: Consumer(
          builder: (context, ref, child) => Column(
            children: [
              DrawerHeaderWidget(title: 'Menu'),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      const Divider(),
                      SectionHeader(title: 'Account'),
                      AccountSection(),
                      const Divider(),
                      SectionHeader(title: 'Data Management'),
                      DataManagementSection(),
                      ProUpgradeSection(),
                      AboutSection(),
                    ],
                  ),
                ),
              ),
              DrawerFooter(),
            ],
          ),
        ),
      ),
    );
  }
}

class _HubStatusCard extends StatelessWidget {
  final PredictWindHubStatus? status;
  final Future<void> Function() onRefresh;
  const _HubStatusCard({required this.status, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final s = status;

    String title;
    String detail;
    IconData icon;
    Color color;

    switch (s?.state) {
      case null:
        title = 'Checking PredictWind Hub…';
        detail = '';
        icon = Icons.hourglass_top;
        color = theme.colorScheme.outline;
      case PredictWindHubConnectionState.notConfigured:
        title = 'PredictWind Hub not configured';
        detail =
            'Add PREDICTWIND_HUB_URL to dart-defines.json to connect.';
        icon = Icons.link_off;
        color = theme.colorScheme.outline;
      case PredictWindHubConnectionState.missingCredentials:
        title = 'PredictWind Hub found — no login configured';
        detail = 'Add PREDICTWIND_HUB_USERNAME/PASSWORD to '
            'dart-defines.json to sign in.';
        icon = Icons.lock_outline;
        color = theme.colorScheme.tertiary;
      case PredictWindHubConnectionState.connected:
        title = 'PredictWind Hub connected';
        detail = '';
        icon = Icons.wifi;
        color = theme.colorScheme.primary;
      case PredictWindHubConnectionState.authFailed:
        title = 'PredictWind Hub sign-in failed';
        detail = 'Check PREDICTWIND_HUB_USERNAME/PASSWORD.';
        icon = Icons.lock_outline;
        color = theme.colorScheme.tertiary;
      case PredictWindHubConnectionState.unreachable:
        title = 'PredictWind Hub unreachable';
        detail = s?.detail ?? "Check the boat's network connection.";
        icon = Icons.wifi_off;
        color = theme.colorScheme.error;
    }

    return Card(
      child: ListTile(
        leading: Icon(icon, color: color),
        title: Text(title),
        subtitle: detail.isEmpty ? null : Text(detail),
        trailing: IconButton(
          icon: const Icon(Icons.refresh),
          tooltip: 'Refresh',
          onPressed: onRefresh,
        ),
      ),
    );
  }
}

class _PositionCard extends StatelessWidget {
  final PredictWindBoatData? boatData;
  final LocationResult? phoneLocation;
  const _PositionCard({required this.boatData, required this.phoneLocation});

  @override
  Widget build(BuildContext context) {
    final lat = boatData?.latitude ?? phoneLocation?.position?.latitude;
    final lon = boatData?.longitude ?? phoneLocation?.position?.longitude;
    final source = boatData?.latitude != null
        ? 'PredictWind Hub'
        : (phoneLocation?.isSuccess ?? false)
            ? 'Phone GPS'
            : null;

    return Card(
      child: ListTile(
        leading: const Icon(Icons.gps_fixed),
        title: Text(
          lat != null && lon != null
              ? '${lat.toStringAsFixed(5)}, ${lon.toStringAsFixed(5)}'
              : 'Position unavailable',
        ),
        subtitle: Text(
          source != null
              ? 'Source: $source'
              : _phoneFailureReason(phoneLocation),
        ),
      ),
    );
  }

  String _phoneFailureReason(LocationResult? r) {
    switch (r?.failureReason) {
      case null:
        return 'Checking…';
      case LocationFailureReason.serviceDisabled:
        return 'Location services are turned off.';
      case LocationFailureReason.permissionDenied:
        return 'Location permission denied.';
      case LocationFailureReason.error:
        return 'Could not get a GPS fix.';
    }
  }
}

class _WindCard extends StatelessWidget {
  final PredictWindBoatData? boatData;
  const _WindCard({required this.boatData});

  @override
  Widget build(BuildContext context) {
    final speed = boatData?.windSpeedKt;
    final dir = boatData?.windDirectionDeg;

    return Card(
      child: ListTile(
        leading: const Icon(Icons.air),
        title: Text(
          speed != null
              ? '${speed.toStringAsFixed(1)} kt'
                  '${dir != null ? ' @ ${dir.toStringAsFixed(0)}°' : ''}'
              : 'Wind data unavailable',
        ),
        subtitle: speed == null
            ? const Text('Requires a connected PredictWind Hub.')
            : const Text('True wind, from the PredictWind Hub'),
      ),
    );
  }
}
