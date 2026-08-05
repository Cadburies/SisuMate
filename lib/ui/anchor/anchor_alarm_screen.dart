import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../components/title_tile.dart';
import '../components/common_drawer.dart';
import '../../core/di.dart';
import '../../models/models.dart';
import '../../services/anchor_alarm_service.dart';
import '../../services/location_service.dart';
import '../../services/predictwind_datahub_service.dart';

final activeAnchorWatchProvider = StreamProvider<AnchorWatch?>((ref) {
  return ref.watch(anchorWatchRepositoryProvider).watchActive();
});

/// #256 — Anchor Alarm: set/edit the anchor position, a chain-scope
/// geofence circle (default ratio from Settings, always adjustable), and
/// an optional wind-swing danger-zone sector. Sources GPS/wind from a
/// connected PredictWind Hub when available, falling back to phone GPS for
/// position only (no phone-native wind source exists).
///
/// The alarm (system sound + haptic, repeating every 2s while triggered)
/// only fires while this screen is open and the app is in the foreground —
/// there is no background/lock-screen service yet (tracked separately;
/// see the issue's Notes on background-execution infrastructure).
class AnchorAlarmScreen extends ConsumerStatefulWidget {
  const AnchorAlarmScreen({
    super.key,
    this.locationService = const LocationService(),
    this.hubService = const PredictWindDatahubService(),
    this.httpClient,
    this.pollInterval = const Duration(seconds: 20),
  });

  final LocationService locationService;
  final PredictWindDatahubService hubService;
  final http.Client? httpClient;

  /// Auto-refresh cadence — a real, lingering `Timer.periodic` is a classic
  /// `flutter_test` hang source (the test binding waits on pending real
  /// timers at teardown), so tests pass `null` to disable it and drive
  /// `_refresh()`/alarm evaluation explicitly instead.
  final Duration? pollInterval;

  @override
  ConsumerState<AnchorAlarmScreen> createState() => _AnchorAlarmScreenState();
}

class _AnchorAlarmScreenState extends ConsumerState<AnchorAlarmScreen> {
  static const _defaultRadiusMeters = 30.0;
  static const _alarmService = AnchorAlarmService();

  bool _loading = true;
  PredictWindHubStatus? _hubStatus;
  PredictWindBoatData? _boatData;
  LocationResult? _phoneLocation;

  bool _alarmActive = false;
  bool _isOutsideCircle = false;
  bool _isInDangerZone = false;

  Timer? _pollTimer;
  Timer? _alarmTimer;

  @override
  void initState() {
    super.initState();
    unawaited(_refresh());
    final interval = widget.pollInterval;
    if (interval != null) {
      _pollTimer = Timer.periodic(interval, (_) => _refresh());
    }
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _alarmTimer?.cancel();
    super.dispose();
  }

  double? get _boatLat => _boatData?.latitude ?? _phoneLocation?.position?.latitude;
  double? get _boatLon => _boatData?.longitude ?? _phoneLocation?.position?.longitude;

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
    _recomputeAlarm();
  }

  void _recomputeAlarm() {
    final anchorWatch = ref.read(activeAnchorWatchProvider).value;
    final lat = _boatLat;
    final lon = _boatLon;

    var outside = false;
    var inDanger = false;
    if (anchorWatch != null && lat != null && lon != null) {
      outside = _alarmService.isOutsideCircle(
        boatLat: lat,
        boatLon: lon,
        anchorLat: anchorWatch.anchorLat,
        anchorLon: anchorWatch.anchorLon,
        radiusMeters: anchorWatch.radiusMeters,
      );
      inDanger = anchorWatch.dangerZoneEnabled &&
          _alarmService.isInDangerZone(
            boatLat: lat,
            boatLon: lon,
            anchorLat: anchorWatch.anchorLat,
            anchorLon: anchorWatch.anchorLon,
            centerDeg: anchorWatch.dangerZoneCenterDeg,
            widthDeg: anchorWatch.dangerZoneWidthDeg,
            radiusMeters: anchorWatch.dangerZoneRadiusMeters,
          );
    }
    final active = outside || inDanger;

    if (mounted) {
      setState(() {
        _alarmActive = active;
        _isOutsideCircle = outside;
        _isInDangerZone = inDanger;
      });
    }

    _alarmTimer?.cancel();
    _alarmTimer = null;
    if (active) {
      _playAlarmTick();
      _alarmTimer = Timer.periodic(const Duration(seconds: 2), (_) => _playAlarmTick());
    }
  }

  void _playAlarmTick() {
    SystemSound.play(SystemSoundType.alert);
    HapticFeedback.vibrate();
  }

  Future<void> _dropAnchor() async {
    final lat = _boatLat;
    final lon = _boatLon;
    if (lat == null || lon == null) return;

    final settings = await ref.read(userSettingsProvider.future);
    final ratio = settings?.defaultAnchorScopeRatio ?? 5.0;
    final depth = _boatData?.depthMeters;
    final radius = depth != null
        ? _alarmService.suggestRadiusMeters(depthMeters: depth, scopeRatio: ratio)
        : _defaultRadiusMeters;

    final watch = AnchorWatch()
      ..anchorLat = lat
      ..anchorLon = lon
      ..scopeRatio = ratio
      ..radiusMeters = radius;
    await ref.read(anchorWatchRepositoryProvider).dropAnchor(watch);
  }

  Future<void> _editPosition(AnchorWatch anchorWatch) async {
    final latCtrl =
        TextEditingController(text: anchorWatch.anchorLat.toStringAsFixed(6));
    final lonCtrl =
        TextEditingController(text: anchorWatch.anchorLon.toStringAsFixed(6));
    try {
      await _showEditPositionDialog(anchorWatch, latCtrl, lonCtrl);
    } finally {
      latCtrl.dispose();
      lonCtrl.dispose();
    }
  }

  /// Split out of [_editPosition] only so the two controllers it creates
  /// have a single, obvious disposal point (`finally`, above) regardless of
  /// how the dialog closes — undisposed `TextEditingController`s are a real
  /// leak `flutter_test`'s leak detector flags, and under memory pressure
  /// that detector's GC/finalizer wait can look like the test hanging.
  Future<void> _showEditPositionDialog(
    AnchorWatch anchorWatch,
    TextEditingController latCtrl,
    TextEditingController lonCtrl,
  ) async {
    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Move Anchor'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextButton.icon(
              icon: const Icon(Icons.my_location),
              label: const Text('Use current GPS position'),
              onPressed: () {
                final lat = _boatLat;
                final lon = _boatLon;
                if (lat != null && lon != null) {
                  latCtrl.text = lat.toStringAsFixed(6);
                  lonCtrl.text = lon.toStringAsFixed(6);
                }
              },
            ),
            TextField(
              controller: latCtrl,
              decoration: const InputDecoration(labelText: 'Latitude'),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true, signed: true),
            ),
            TextField(
              controller: lonCtrl,
              decoration: const InputDecoration(labelText: 'Longitude'),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true, signed: true),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (saved != true) return;

    final lat = double.tryParse(latCtrl.text.trim());
    final lon = double.tryParse(lonCtrl.text.trim());
    if (lat == null || lon == null) return;

    final updated = anchorWatch
      ..anchorLat = lat
      ..anchorLon = lon;
    await ref.read(anchorWatchRepositoryProvider).updateWatch(updated);
  }

  Future<void> _weighAnchor(int id) async {
    await ref.read(anchorWatchRepositoryProvider).weighAnchor(id);
  }

  @override
  Widget build(BuildContext context) {
    final activeWatch = ref.watch(activeAnchorWatchProvider).value;
    ref.listen(activeAnchorWatchProvider, (previous, next) => _recomputeAlarm());

    final canDrop = _boatLat != null && _boatLon != null;

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
                            if (_alarmActive) ...[
                              _AlarmBanner(
                                outsideCircle: _isOutsideCircle,
                                inDangerZone: _isInDangerZone,
                              ),
                              const SizedBox(height: 12),
                            ],
                            if (activeWatch == null)
                              _DropAnchorCard(canDrop: canDrop, onDrop: _dropAnchor)
                            else ...[
                              _AnchorStatusCard(
                                activeWatch: activeWatch,
                                boatLat: _boatLat,
                                boatLon: _boatLon,
                                onEditPosition: () => _editPosition(activeWatch),
                                onWeighAnchor: () => _weighAnchor(activeWatch.id),
                              ),
                              const SizedBox(height: 12),
                              _ScopeCard(
                                activeWatch: activeWatch,
                                depthMeters: _boatData?.depthMeters,
                              ),
                              const SizedBox(height: 12),
                              _DangerZoneCard(activeWatch: activeWatch),
                            ],
                            const SizedBox(height: 12),
                            _HubStatusCard(status: _hubStatus, onRefresh: _refresh),
                            const SizedBox(height: 12),
                            _PositionCard(
                              boatData: _boatData,
                              phoneLocation: _phoneLocation,
                            ),
                            const SizedBox(height: 12),
                            _WindCard(boatData: _boatData),
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

class _AlarmBanner extends StatelessWidget {
  final bool outsideCircle;
  final bool inDangerZone;
  const _AlarmBanner({required this.outsideCircle, required this.inDangerZone});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final message = outsideCircle && inDangerZone
        ? 'ANCHOR ALARM — outside the safe circle and in the danger zone!'
        : inDangerZone
            ? 'ANCHOR ALARM — the boat has swung into the danger zone!'
            : 'ANCHOR ALARM — the boat has dragged outside the safe circle!';

    return Card(
      color: theme.colorScheme.error,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.warning_amber, color: theme.colorScheme.onError, size: 32),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  color: theme.colorScheme.onError,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DropAnchorCard extends StatelessWidget {
  final bool canDrop;
  final VoidCallback onDrop;
  const _DropAnchorCard({required this.canDrop, required this.onDrop});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text('No anchor set', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text(
              'Drops at the current GPS position with a scope-based alarm '
              'radius — adjustable after.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: canDrop ? onDrop : null,
              icon: const Icon(Icons.anchor),
              label: const Text('Drop Anchor Here'),
            ),
            if (!canDrop)
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text('Waiting for a GPS fix…'),
              ),
          ],
        ),
      ),
    );
  }
}

class _AnchorStatusCard extends StatelessWidget {
  final AnchorWatch activeWatch;
  final double? boatLat;
  final double? boatLon;
  final VoidCallback onEditPosition;
  final VoidCallback onWeighAnchor;
  const _AnchorStatusCard({
    required this.activeWatch,
    required this.boatLat,
    required this.boatLon,
    required this.onEditPosition,
    required this.onWeighAnchor,
  });

  @override
  Widget build(BuildContext context) {
    String subtitle;
    final lat = boatLat;
    final lon = boatLon;
    if (lat != null && lon != null) {
      final dist = const AnchorAlarmService().distanceMeters(
        lat1: activeWatch.anchorLat,
        lon1: activeWatch.anchorLon,
        lat2: lat,
        lon2: lon,
      );
      subtitle = '${dist.toStringAsFixed(0)} m from anchor';
    } else {
      subtitle = 'Waiting for a GPS fix…';
    }

    return Card(
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.anchor),
            title: Text(
              '${activeWatch.anchorLat.toStringAsFixed(5)}, '
              '${activeWatch.anchorLon.toStringAsFixed(5)}',
            ),
            subtitle: Text(subtitle),
          ),
          OverflowBar(
            alignment: MainAxisAlignment.end,
            children: [
              TextButton.icon(
                onPressed: onEditPosition,
                icon: const Icon(Icons.edit_location_alt),
                label: const Text('Edit position'),
              ),
              TextButton.icon(
                onPressed: onWeighAnchor,
                icon: const Icon(Icons.anchor_outlined),
                label: const Text('Weigh anchor'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ScopeCard extends ConsumerStatefulWidget {
  final AnchorWatch activeWatch;
  final double? depthMeters;
  const _ScopeCard({required this.activeWatch, required this.depthMeters});

  @override
  ConsumerState<_ScopeCard> createState() => _ScopeCardState();
}

class _ScopeCardState extends ConsumerState<_ScopeCard> {
  late double _ratio;
  late double _radius;

  @override
  void initState() {
    super.initState();
    _ratio = widget.activeWatch.scopeRatio;
    _radius = widget.activeWatch.radiusMeters;
  }

  @override
  void didUpdateWidget(covariant _ScopeCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.activeWatch.id != widget.activeWatch.id) {
      _ratio = widget.activeWatch.scopeRatio;
      _radius = widget.activeWatch.radiusMeters;
    }
  }

  Future<void> _persist() async {
    final updated = widget.activeWatch
      ..scopeRatio = _ratio
      ..radiusMeters = _radius;
    await ref.read(anchorWatchRepositoryProvider).updateWatch(updated);
  }

  @override
  Widget build(BuildContext context) {
    final depth = widget.depthMeters;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Scope & Alarm Radius', style: Theme.of(context).textTheme.titleSmall),
            Row(
              children: [
                const SizedBox(width: 90, child: Text('Scope ratio')),
                Expanded(
                  child: Slider(
                    value: _ratio.clamp(1, 10),
                    min: 1,
                    max: 10,
                    divisions: 18,
                    label: '${_ratio.toStringAsFixed(1)}:1',
                    onChanged: (v) => setState(() => _ratio = v),
                    onChangeEnd: (_) => _persist(),
                  ),
                ),
                SizedBox(width: 48, child: Text('${_ratio.toStringAsFixed(1)}:1')),
              ],
            ),
            Row(
              children: [
                const SizedBox(width: 90, child: Text('Radius')),
                Expanded(
                  child: Slider(
                    value: _radius.clamp(5, 300),
                    min: 5,
                    max: 300,
                    divisions: 59,
                    label: '${_radius.toStringAsFixed(0)} m',
                    onChanged: (v) => setState(() => _radius = v),
                    onChangeEnd: (_) => _persist(),
                  ),
                ),
                SizedBox(width: 48, child: Text('${_radius.toStringAsFixed(0)} m')),
              ],
            ),
            if (depth != null)
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  onPressed: () {
                    setState(() {
                      _radius = const AnchorAlarmService()
                          .suggestRadiusMeters(depthMeters: depth, scopeRatio: _ratio);
                    });
                    _persist();
                  },
                  child: Text('Suggest from live depth (${depth.toStringAsFixed(1)} m)'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _DangerZoneCard extends ConsumerStatefulWidget {
  final AnchorWatch activeWatch;
  const _DangerZoneCard({required this.activeWatch});

  @override
  ConsumerState<_DangerZoneCard> createState() => _DangerZoneCardState();
}

class _DangerZoneCardState extends ConsumerState<_DangerZoneCard> {
  late double _centerDeg;
  late double _widthDeg;
  late double _radiusMeters;

  @override
  void initState() {
    super.initState();
    _centerDeg = widget.activeWatch.dangerZoneCenterDeg;
    _widthDeg = widget.activeWatch.dangerZoneWidthDeg;
    _radiusMeters = widget.activeWatch.dangerZoneRadiusMeters;
  }

  @override
  void didUpdateWidget(covariant _DangerZoneCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.activeWatch.id != widget.activeWatch.id) {
      _centerDeg = widget.activeWatch.dangerZoneCenterDeg;
      _widthDeg = widget.activeWatch.dangerZoneWidthDeg;
      _radiusMeters = widget.activeWatch.dangerZoneRadiusMeters;
    }
  }

  Future<void> _persist({bool? enabled}) async {
    final updated = widget.activeWatch
      ..dangerZoneEnabled = enabled ?? widget.activeWatch.dangerZoneEnabled
      ..dangerZoneCenterDeg = _centerDeg
      ..dangerZoneWidthDeg = _widthDeg
      ..dangerZoneRadiusMeters = _radiusMeters;
    await ref.read(anchorWatchRepositoryProvider).updateWatch(updated);
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.activeWatch.dangerZoneEnabled;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Danger zone'),
              subtitle: const Text(
                "Alarm if the boat swings into this sector, even inside the safe circle.",
              ),
              value: enabled,
              onChanged: (v) => _persist(enabled: v),
            ),
            if (enabled) ...[
              _sliderRow(
                label: 'Center bearing',
                value: _centerDeg,
                min: 0,
                max: 360,
                unit: '°T',
                onChanged: (v) => setState(() => _centerDeg = v),
              ),
              _sliderRow(
                label: 'Width',
                value: _widthDeg,
                min: 10,
                max: 180,
                unit: '°',
                onChanged: (v) => setState(() => _widthDeg = v),
              ),
              _sliderRow(
                label: 'Radius',
                value: _radiusMeters,
                min: 5,
                max: 300,
                unit: ' m',
                onChanged: (v) => setState(() => _radiusMeters = v),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _sliderRow({
    required String label,
    required double value,
    required double min,
    required double max,
    required String unit,
    required ValueChanged<double> onChanged,
  }) {
    return Row(
      children: [
        SizedBox(width: 100, child: Text(label)),
        Expanded(
          child: Slider(
            value: value.clamp(min, max),
            min: min,
            max: max,
            label: '${value.toStringAsFixed(0)}$unit',
            onChanged: onChanged,
            onChangeEnd: (_) => _persist(),
          ),
        ),
        SizedBox(width: 56, child: Text('${value.toStringAsFixed(0)}$unit')),
      ],
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
