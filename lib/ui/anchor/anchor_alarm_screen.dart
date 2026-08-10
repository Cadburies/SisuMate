import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;

import '../components/title_tile.dart';
import '../components/common_drawer.dart';
import '../../core/app_router.dart';
import '../../core/di.dart';
import '../../models/models.dart';
import '../../providers/shopping_provider.dart' show activeBoatProvider;
import '../../services/anchor_alarm_service.dart';
import '../../services/boat_position_service.dart';
import '../../services/predictwind_datahub_service.dart';
import 'anchor_chart_map.dart';
import 'anchor_info_panel.dart';

final activeAnchorWatchProvider = StreamProvider<AnchorWatch?>((ref) {
  return ref.watch(anchorWatchRepositoryProvider).watchActive();
});

/// #256 follow-up — cruisers rarely pay out more than ~120m of rode, so
/// the radius sliders (scope circle + danger-zone sector) stay bounded to
/// that common range. [_RadiusEditor]'s paired text field still accepts
/// any value beyond it for the rare setup that needs more.
const _maxSliderRadiusMeters = 120.0;

/// #256 — Anchor Alarm: set/edit the anchor position, a chain-scope
/// geofence circle (default ratio from Settings, always adjustable), and
/// an optional wind-swing danger-zone sector.
///
/// #303 — Position prefers boat instruments ([BoatPositionService] multi-
/// source failover), then phone GPS when instruments have no usable fix.
/// UI shows the active source. Losing instruments alone is never treated
/// as a drag — alarms evaluate only when a position (either source) exists.
/// Depth/wind stay instrument-only when available.
///
/// #307 — Also evaluates min-depth and strong-wind thresholds from Settings
/// (and an AIS arming switch with no feed yet). Distinct reason chips;
/// system alert + haptic for all conditions.
///
/// Alarms only fire while this screen is open and the app is in the
/// foreground — no background service yet.
class AnchorAlarmScreen extends ConsumerStatefulWidget {
  const AnchorAlarmScreen({
    super.key,
    this.hubService = const PredictWindDatahubService(),
    this.httpClient,
    this.pollInterval = const Duration(seconds: 20),
    this.showChartMap = true,
    this.positionService = const BoatPositionService(),
    /// Production: true (#303). Widget tests that assert Hub-only copy pass
    /// false so Geolocator is never hit under flutter_test.
    this.allowPhoneFallback = true,
  });

  final PredictWindDatahubService hubService;
  final http.Client? httpClient;
  final BoatPositionService positionService;
  final bool allowPhoneFallback;

  /// Auto-refresh cadence — a real, lingering `Timer.periodic` is a classic
  /// `flutter_test` hang source (the test binding waits on pending real
  /// timers at teardown), so tests pass `null` to disable it and drive
  /// `_refresh()`/alarm evaluation explicitly instead.
  final Duration? pollInterval;

  /// #268 — flutter_map's MapController dispose deadlocks the widget-test
  /// binding for minutes. Screen-level tests set this false; chart-map
  /// behaviour is covered by `anchor_chart_map_test.dart` instead.
  final bool showChartMap;

  @override
  ConsumerState<AnchorAlarmScreen> createState() => _AnchorAlarmScreenState();
}

class _AnchorAlarmScreenState extends ConsumerState<AnchorAlarmScreen>
    with SingleTickerProviderStateMixin {
  static const _defaultRadiusMeters = 30.0;
  static const _alarmService = AnchorAlarmService();

  // True only until the very first fetch completes — after that, refreshes
  // (periodic or manual) update data quietly in place. Swapping the whole
  // body out for a spinner on every refresh (the old behavior) tore down
  // in-progress Slider drags and made editing the anchor position
  // effectively impossible — see #256 follow-up.
  bool _initialLoadDone = false;
  bool _isRefreshing = false;
  PredictWindHubStatus? _hubStatus;
  PredictWindBoatData? _boatData;
  /// #303 — lat/lon may come from phone when instruments lack a fix.
  double? _positionLat;
  double? _positionLon;
  BoatPositionSource? _positionSource;
  String _positionSourceLabel = 'No position';

  bool _alarmActive = false;
  bool _isOutsideCircle = false;
  bool _isInDangerZone = false;
  bool _isShallow = false;
  bool _isStrongWind = false;
  bool _isAisRisk = false;

  Timer? _pollTimer;
  Timer? _alarmTimer;
  // #266 — Watch (edit/alarm) vs Info (read-only instruments).
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    unawaited(_refresh());
    final interval = widget.pollInterval;
    if (interval != null) {
      _pollTimer = Timer.periodic(interval, (_) => _refresh());
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _pollTimer?.cancel();
    _alarmTimer?.cancel();
    super.dispose();
  }

  // #303 — best available lat/lon (instruments or phone).
  double? get _boatLat => _positionLat;
  double? get _boatLon => _positionLon;

  /// #263 — dart-defines-backed [widget.hubService] is the base; saved
  /// DataHub settings layer on top. Multi-source failover (HA, remote) is
  /// handled inside [BoatPositionService].
  Future<PredictWindDatahubService> _effectiveHubService() async {
    final settings = await ref.read(userSettingsProvider.future);
    if (settings == null) return widget.hubService;

    final savedUrl = settings.predictwindHubLocalUrl.trim();
    final user = settings.predictwindHubUsername.isNotEmpty
        ? settings.predictwindHubUsername
        : null;
    final pass = settings.predictwindHubPassword.isNotEmpty
        ? settings.predictwindHubPassword
        : null;

    if (savedUrl.isEmpty && user == null && pass == null) {
      return widget.hubService;
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

  Future<void> _refresh() async {
    setState(() => _isRefreshing = true);
    final settings = await ref.read(userSettingsProvider.future);
    final hubService = await _effectiveHubService();
    final pos = await widget.positionService.fetchBest(
      settings: settings,
      hubService: hubService,
      client: widget.httpClient,
      allowPhoneFallback: widget.allowPhoneFallback,
    );
    if (!mounted) return;
    setState(() {
      _hubStatus = pos.instruments.hubStatus;
      _boatData = pos.boatData;
      _positionLat = pos.latitude;
      _positionLon = pos.longitude;
      _positionSource = pos.positionSource;
      _positionSourceLabel = pos.positionSourceLabel;
      _initialLoadDone = true;
      _isRefreshing = false;
    });
    // #274 — offline polar learning: store under-sail samples when engines
    // are not showing revs and SOG/wind are valid.
    final boatData = pos.boatData;
    if (boatData != null) {
      unawaited(_maybeCollectPolarSample(boatData));
    }
    _recomputeAlarm();
  }

  Future<void> _maybeCollectPolarSample(PredictWindBoatData data) async {
    final boat = ref.read(activeBoatProvider).asData?.value;
    final boatId = boat?.supabaseId ?? '';
    if (boatId.isEmpty) return;
    try {
      await ref.read(sailingPolarCollectorProvider).maybeRecord(
            data: data,
            boatSupabaseId: boatId,
            enginePortRpm: data.enginePortRpm,
            engineStbdRpm: data.engineStbdRpm,
          );
    } catch (_) {
      // Best-effort; never break anchor alarm on polar collection.
    }
  }

  void _recomputeAlarm() {
    final anchorWatch = ref.read(activeAnchorWatchProvider).value;
    final settings = ref.read(userSettingsProvider).asData?.value;
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
            innerRadiusMeters: anchorWatch.dangerZoneInnerRadiusMeters,
            // #273 — outer edge is the geofence perimeter.
            outerRadiusMeters: anchorWatch.radiusMeters,
          );
    }

    // #307 — shallow / wind / AIS (AIS is a no-op until a feed exists).
    final shallow = _alarmService.isShallow(
      depthMeters: _boatData?.depthMeters,
      minDepthMeters: settings?.anchorMinDepthMeters ?? 0,
    );
    final windKt = _boatData?.apparentWindSpeedKt ?? _boatData?.windSpeedKt;
    final strongWind = _alarmService.isStrongWind(
      windKt: windKt,
      maxWindKt: settings?.anchorMaxWindKt ?? 0,
    );
    final ais = _alarmService.isAisCollisionRisk(
      enabled: settings?.anchorAisAlarmEnabled ?? false,
    );

    final active = outside || inDanger || shallow || strongWind || ais;

    if (mounted) {
      setState(() {
        _alarmActive = active;
        _isOutsideCircle = outside;
        _isInDangerZone = inDanger;
        _isShallow = shallow;
        _isStrongWind = strongWind;
        _isAisRisk = ais;
      });
    }

    _alarmTimer?.cancel();
    _alarmTimer = null;
    if (active) {
      _playAlarmTick();
      _alarmTimer =
          Timer.periodic(const Duration(seconds: 2), (_) => _playAlarmTick());
    }
  }

  void _playAlarmTick() {
    // #307 — system alert for all conditions (bundled tones later).
    SystemSound.play(SystemSoundType.alert);
    HapticFeedback.vibrate();
  }

  Future<void> _dropAnchor() async {
    final lat = _boatLat;
    final lon = _boatLon;
    if (lat == null || lon == null) return;

    final settings = await ref.read(userSettingsProvider.future);
    final ratio = settings?.defaultAnchorScopeRatio ?? 5.0;
    final roller = settings?.anchorRollerHeightMeters ?? 0;
    final depth = _boatData?.depthMeters;
    final radius = depth != null
        ? _alarmService.suggestRadiusMeters(
            depthMeters: depth,
            scopeRatio: ratio,
            freeboardMeters: roller,
          )
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
              onPressed: _boatLat != null && _boatLon != null
                  ? () {
                      latCtrl.text = _boatLat!.toStringAsFixed(6);
                      lonCtrl.text = _boatLon!.toStringAsFixed(6);
                    }
                  : null,
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
              // #266 — Watch (controls) | Info (instruments). Matches Chef/
              // Cocktails tab pattern under the title bar (theme.md §5).
              TabBar(
                controller: _tabController,
                tabs: const [
                  Tab(icon: Icon(Icons.anchor), text: 'Watch'),
                  Tab(icon: Icon(Icons.info_outline), text: 'Info'),
                ],
              ),
              Expanded(
                child: !_initialLoadDone
                    ? const Center(child: CircularProgressIndicator())
                    : TabBarView(
                        controller: _tabController,
                        children: [
                          RefreshIndicator(
                            onRefresh: _refresh,
                            child: ListView(
                              padding: const EdgeInsets.all(12),
                              children: [
                                if (_alarmActive) ...[
                                  _AlarmBanner(
                                    outsideCircle: _isOutsideCircle,
                                    inDangerZone: _isInDangerZone,
                                    shallow: _isShallow,
                                    strongWind: _isStrongWind,
                                    ais: _isAisRisk,
                                  ),
                                  const SizedBox(height: 12),
                                ] else if (activeWatch != null &&
                                    !canDrop) ...[
                                  _NoFixWarningBanner(
                                      hubState: _hubStatus?.state),
                                  const SizedBox(height: 12),
                                ],
                                if (activeWatch == null)
                                  _DropAnchorCard(
                                      canDrop: canDrop, onDrop: _dropAnchor)
                                else ...[
                                  _AnchorStatusCard(
                                    activeWatch: activeWatch,
                                    boatLat: _boatLat,
                                    boatLon: _boatLon,
                                    onEditPosition: () =>
                                        _editPosition(activeWatch),
                                    onWeighAnchor: () =>
                                        _weighAnchor(activeWatch.id),
                                  ),
                                  if (widget.showChartMap) ...[
                                    const SizedBox(height: 12),
                                    AnchorChartMap(
                                      activeWatch: activeWatch,
                                      boatLat: _boatLat,
                                      boatLon: _boatLon,
                                      // #304 — map radius drag can back-solve scope.
                                      depthMeters: _boatData?.depthMeters,
                                    ),
                                  ],
                                  const SizedBox(height: 12),
                                  _ScopeCard(
                                    activeWatch: activeWatch,
                                    depthMeters: _boatData?.depthMeters,
                                    rollerHeightMeters: ref
                                            .watch(userSettingsProvider)
                                            .asData
                                            ?.value
                                            ?.anchorRollerHeightMeters ??
                                        0,
                                  ),
                                  const SizedBox(height: 12),
                                  _DangerZoneCard(activeWatch: activeWatch),
                                ],
                                const SizedBox(height: 12),
                                _HubStatusCard(
                                  status: _hubStatus,
                                  isRefreshing: _isRefreshing,
                                  onRefresh: _refresh,
                                  onConfigure: () async {
                                    // #306 — instruments live in global Settings.
                                    await context
                                        .push(AppRoutes.boatInstruments);
                                    if (mounted) unawaited(_refresh());
                                  },
                                ),
                                const SizedBox(height: 12),
                                _PositionCard(
                                  boatData: _boatData,
                                  positionLat: _positionLat,
                                  positionLon: _positionLon,
                                  positionSourceLabel: _positionSourceLabel,
                                  positionSource: _positionSource,
                                ),
                                const SizedBox(height: 12),
                                _WindCard(boatData: _boatData),
                              ],
                            ),
                          ),
                          RefreshIndicator(
                            onRefresh: _refresh,
                            child: AnchorInfoPanel(
                              activeWatch: activeWatch,
                              boatData: _boatData,
                              positionLat: _positionLat,
                              positionLon: _positionLon,
                              positionSourceLabel: _positionSourceLabel,
                            ),
                          ),
                        ],
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
  final bool shallow;
  final bool strongWind;
  final bool ais;
  const _AlarmBanner({
    required this.outsideCircle,
    required this.inDangerZone,
    this.shallow = false,
    this.strongWind = false,
    this.ais = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // #307 — list every active reason so multi-condition is clear.
    final reasons = <String>[
      if (outsideCircle) 'Drag (outside circle)',
      if (inDangerZone) 'Danger zone',
      if (shallow) 'Shallow (min depth)',
      if (strongWind) 'Strong wind',
      if (ais) 'AIS risk',
    ];
    final message = reasons.isEmpty
        ? 'ANCHOR ALARM'
        : 'ANCHOR ALARM — ${reasons.join(' · ')}';

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
  /// #307 — bow roller height from Settings (freeboard in scope math).
  final double rollerHeightMeters;
  const _ScopeCard({
    required this.activeWatch,
    required this.depthMeters,
    this.rollerHeightMeters = 0,
  });

  @override
  ConsumerState<_ScopeCard> createState() => _ScopeCardState();
}

class _ScopeCardState extends ConsumerState<_ScopeCard> {
  static const _alarm = AnchorAlarmService();

  late double _ratio;
  late double _radius;
  /// True while the user is mid-drag on a local control so an external
  /// watch update (map persist) doesn't clobber the in-flight gesture.
  bool _editingLocally = false;

  @override
  void initState() {
    super.initState();
    _ratio = widget.activeWatch.scopeRatio;
    _radius = widget.activeWatch.radiusMeters;
  }

  @override
  void didUpdateWidget(covariant _ScopeCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // #304 — re-sync from the watch when the map (or another card) changes
    // radius/scope, not only when the watch id changes.
    if (_editingLocally) return;
    final w = widget.activeWatch;
    if (oldWidget.activeWatch.id != w.id ||
        oldWidget.activeWatch.scopeRatio != w.scopeRatio ||
        oldWidget.activeWatch.radiusMeters != w.radiusMeters) {
      _ratio = w.scopeRatio;
      _radius = w.radiusMeters;
    }
  }

  Future<void> _persist() async {
    final updated = widget.activeWatch
      ..scopeRatio = _ratio
      ..radiusMeters = _radius;
    await ref.read(anchorWatchRepositoryProvider).updateWatch(updated);
  }

  double get _roller =>
      widget.rollerHeightMeters < 0 ? 0 : widget.rollerHeightMeters;

  /// #304/#307 — when live depth is known, radius = (depth + roller) × scope.
  void _applyScope(double ratio) {
    _ratio = ratio;
    final depth = widget.depthMeters;
    if (depth != null && depth > 0) {
      _radius = _alarm.suggestRadiusMeters(
        depthMeters: depth,
        scopeRatio: _ratio,
        freeboardMeters: _roller,
      );
    }
  }

  /// #304/#307 — when live depth is known, back-solve scope from radius.
  void _applyRadius(double radius) {
    _radius = radius;
    final depth = widget.depthMeters;
    if (depth != null && depth > 0) {
      final next = _alarm.scopeFromRadius(
        radiusMeters: _radius,
        depthMeters: depth,
        freeboardMeters: _roller,
      );
      if (next != null) _ratio = next;
    }
  }

  @override
  Widget build(BuildContext context) {
    final depth = widget.depthMeters;
    final depthKnown = depth != null && depth > 0;
    final rollerNote = _roller > 0
        ? ' + roller ${_roller.toStringAsFixed(1)} m'
        : '';
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Scope & Alarm Radius',
                style: Theme.of(context).textTheme.titleSmall),
            if (depthKnown)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  'Linked to live depth (${depth.toStringAsFixed(1)} m$rollerNote): '
                  'changing scope updates radius and vice versa.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  'No live depth — scope and radius edit independently. '
                  'Map radius still stays in sync with the slider.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
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
                    onChangeStart: (_) => _editingLocally = true,
                    onChanged: (v) => setState(() => _applyScope(v)),
                    onChangeEnd: (_) async {
                      await _persist();
                      _editingLocally = false;
                    },
                  ),
                ),
                SizedBox(
                    width: 48,
                    child: Text('${_ratio.toStringAsFixed(1)}:1')),
              ],
            ),
            _RadiusEditor(
              label: 'Radius',
              value: _radius,
              sliderMax: _maxSliderRadiusMeters,
              onChangeStart: () => _editingLocally = true,
              onChanged: (v) => setState(() => _applyRadius(v)),
              onCommit: () async {
                await _persist();
                _editingLocally = false;
              },
            ),
            if (depthKnown)
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  onPressed: () {
                    setState(() {
                      _radius = _alarm.suggestRadiusMeters(
                        depthMeters: depth,
                        scopeRatio: _ratio,
                        freeboardMeters: _roller,
                      );
                    });
                    _persist();
                  },
                  child: Text(
                    'Reset radius from scope × (depth$rollerNote)',
                  ),
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
  late double _innerRadiusMeters;

  @override
  void initState() {
    super.initState();
    _syncFromWatch();
  }

  @override
  void didUpdateWidget(covariant _DangerZoneCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.activeWatch.id != widget.activeWatch.id) _syncFromWatch();
  }

  void _syncFromWatch() {
    _centerDeg = widget.activeWatch.dangerZoneCenterDeg;
    _widthDeg = widget.activeWatch.dangerZoneWidthDeg;
    _innerRadiusMeters = widget.activeWatch.dangerZoneInnerRadiusMeters;
  }

  Future<void> _persist({bool? enabled}) async {
    // #262 — a hazard is typically beyond the safe swinging circle, so the
    // ring's inner edge defaults toward the geofence when (re-)enabled.
    // #273 — outer radius is always the geofence (not independently set);
    // when enabling, seed inner just inside the geofence so the ring has
    // thickness.
    final geofence = widget.activeWatch.radiusMeters;
    if (enabled == true) {
      _innerRadiusMeters = (geofence - 10).clamp(5.0, geofence - 5);
    }
    final updated = widget.activeWatch
      ..dangerZoneEnabled = enabled ?? widget.activeWatch.dangerZoneEnabled
      ..dangerZoneCenterDeg = _centerDeg
      ..dangerZoneWidthDeg = _widthDeg
      ..dangerZoneInnerRadiusMeters = _innerRadiusMeters
      ..dangerZoneOuterRadiusMeters = geofence;
    await ref.read(anchorWatchRepositoryProvider).updateWatch(updated);
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.activeWatch.dangerZoneEnabled;
    final geofence = widget.activeWatch.radiusMeters;
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
                'Alarm if the boat swings into this ring on the geofence '
                'perimeter — e.g. rocks or a lee shore past the safe circle. '
                'Outer edge follows the alarm radius.',
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
              _RadiusEditor(
                label: 'Inner radius',
                value: _innerRadiusMeters,
                // #273 — cannot exceed the geofence (outer edge).
                sliderMax: math.max(10, geofence - 5),
                onChanged: (v) => setState(() => _innerRadiusMeters = v),
                onCommit: _persist,
              ),
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  'Outer edge = alarm radius (${geofence.toStringAsFixed(0)} m)',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
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

/// #256 follow-up — a capped [Slider] (the common cruising range) paired
/// with a free-text field for an exact/uncapped override. Real anchor
/// scope rarely exceeds ~120m of rode, so the slider stays bounded to
/// that, but the text field still accepts any value for the rare setup
/// that needs more — "the slider can stay max 120m" per the product ask,
/// with the override living in the text field instead of raising the cap.
class _RadiusEditor extends StatefulWidget {
  final String label;
  final double value;
  final double sliderMax;
  final ValueChanged<double> onChanged;
  final VoidCallback onCommit;
  /// #304 — optional so danger-zone inner radius can keep the old API.
  final VoidCallback? onChangeStart;
  const _RadiusEditor({
    required this.label,
    required this.value,
    required this.sliderMax,
    required this.onChanged,
    required this.onCommit,
    this.onChangeStart,
  });

  @override
  State<_RadiusEditor> createState() => _RadiusEditorState();
}

class _RadiusEditorState extends State<_RadiusEditor> {
  late final TextEditingController _textCtrl;
  final _textFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    _textCtrl = TextEditingController(text: widget.value.toStringAsFixed(0));
  }

  @override
  void didUpdateWidget(covariant _RadiusEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Keep the field in sync with external changes (slider drag, "suggest
    // from depth") without clobbering text the user is mid-typing.
    final text = widget.value.toStringAsFixed(0);
    if (!_textFocus.hasFocus && _textCtrl.text != text) {
      _textCtrl.text = text;
    }
  }

  @override
  void dispose() {
    _textCtrl.dispose();
    _textFocus.dispose();
    super.dispose();
  }

  void _submitText() {
    final parsed = double.tryParse(_textCtrl.text.trim());
    if (parsed != null && parsed > 0) {
      widget.onChangeStart?.call();
      widget.onChanged(parsed);
      widget.onCommit();
    } else {
      _textCtrl.text = widget.value.toStringAsFixed(0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(width: 90, child: Text(widget.label)),
        Expanded(
          child: Slider(
            value: widget.value.clamp(5, widget.sliderMax),
            min: 5,
            max: widget.sliderMax,
            divisions: widget.sliderMax.round() - 5,
            label: '${widget.value.toStringAsFixed(0)} m',
            onChangeStart: (_) => widget.onChangeStart?.call(),
            onChanged: widget.onChanged,
            onChangeEnd: (_) => widget.onCommit(),
          ),
        ),
        // #315 — wide enough for 100–120+ m with the "m" suffix visible.
        SizedBox(
          width: 96,
          child: TextField(
            controller: _textCtrl,
            focusNode: _textFocus,
            textAlign: TextAlign.end,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              isDense: true,
              suffixText: 'm',
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 10),
            ),
            onSubmitted: (_) => _submitText(),
            onTapOutside: (_) => _submitText(),
          ),
        ),
      ],
    );
  }
}

class _HubStatusCard extends StatelessWidget {
  final PredictWindHubStatus? status;
  final bool isRefreshing;
  final Future<void> Function() onRefresh;
  final VoidCallback onConfigure;
  const _HubStatusCard({
    required this.status,
    required this.isRefreshing,
    required this.onRefresh,
    required this.onConfigure,
  });

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
        title = 'Checking boat instruments…';
        detail = 'DataHub / Home Assistant failover';
        icon = Icons.hourglass_top;
        color = theme.colorScheme.outline;
      case PredictWindHubConnectionState.notConfigured:
        title = 'No instrument source configured';
        detail =
            'Open Settings → Boat instruments to add DataHub, YDWG, or HA.';
        icon = Icons.link_off;
        color = theme.colorScheme.outline;
      case PredictWindHubConnectionState.missingCredentials:
        title = 'Instrument login missing';
        detail =
            'Add DataHub login or Home Assistant token under Boat instruments.';
        icon = Icons.lock_outline;
        color = theme.colorScheme.tertiary;
      case PredictWindHubConnectionState.connected:
        title = s?.detail?.isNotEmpty == true
            ? s!.detail!
            : 'Boat instruments connected';
        detail = s!.viaLocalNetwork
            ? "Via the boat's local network (WiFi)"
            : 'Via internet (remote / beach-bar path)';
        icon = s.viaLocalNetwork ? Icons.wifi : Icons.public;
        color = theme.colorScheme.primary;
      case PredictWindHubConnectionState.authFailed:
        title = 'Instrument sign-in failed';
        detail = s?.detail ?? 'Check DataHub password or HA token.';
        icon = Icons.lock_outline;
        color = theme.colorScheme.tertiary;
      case PredictWindHubConnectionState.unreachable:
        title = 'Boat instruments unreachable';
        detail = s?.detail ??
            'Tried local then internet sources. Check Boat instruments settings.';
        icon = Icons.wifi_off;
        color = theme.colorScheme.error;
    }

    return Card(
      child: ListTile(
        leading: Icon(icon, color: color),
        title: Text(title),
        subtitle: detail.isEmpty ? null : Text(detail),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Two full-size (48x48) IconButtons plus the leading icon left
            // too little width for the title on a real phone screen,
            // wrapping mid-word across 3 lines. Compact density + tight
            // constraints shrink both buttons here (~36x36) without
            // shrinking their icons, freeing enough width for the title.
            IconButton(
              icon: const Icon(Icons.settings_ethernet),
              tooltip: 'Gateway setup',
              onPressed: onConfigure,
              visualDensity: VisualDensity.compact,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
            const SizedBox(width: 4),
            if (isRefreshing)
              const Padding(
                padding: EdgeInsets.all(12),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            else
              IconButton(
                icon: const Icon(Icons.refresh),
                tooltip: 'Refresh',
                onPressed: onRefresh,
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
          ],
        ),
      ),
    );
  }
}

/// #303 — GPS position from instruments or phone fallback.
class _PositionCard extends StatelessWidget {
  final PredictWindBoatData? boatData;
  final double? positionLat;
  final double? positionLon;
  final String positionSourceLabel;
  final BoatPositionSource? positionSource;
  const _PositionCard({
    required this.boatData,
    required this.positionLat,
    required this.positionLon,
    required this.positionSourceLabel,
    required this.positionSource,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasPos = positionLat != null && positionLon != null;
    final fromPhone = positionSource == BoatPositionSource.phoneGps;

    String title;
    String subtitle;
    if (hasPos) {
      title =
          '${positionLat!.toStringAsFixed(5)}, ${positionLon!.toStringAsFixed(5)}';
      subtitle = 'Source: $positionSourceLabel'
          '${fromPhone ? ' (instruments had no fix)' : ''}';
    } else if (boatData == null) {
      title = 'Position unavailable';
      subtitle = 'No instruments and no phone GPS fix.';
    } else if (boatData!.isStale()) {
      title = 'Position unavailable';
      subtitle =
          'Instrument reading stale and phone GPS unavailable — cannot verify.';
    } else {
      title = 'Position unavailable';
      subtitle = 'Waiting for instrument fix or phone GPS.';
    }

    return Card(
      child: ListTile(
        leading: Icon(
          hasPos
              ? (fromPhone ? Icons.phone_android : Icons.gps_fixed)
              : Icons.gps_off,
          color: hasPos ? null : theme.colorScheme.outline,
        ),
        title: Text(title),
        subtitle: Text(subtitle),
      ),
    );
  }
}

/// #256 follow-up — a calm, non-looping warning for "no trustworthy Hub
/// position," shown where the loud [_AlarmBanner] would go (the two are
/// mutually exclusive: the alarm needs a position to evaluate against).
/// Deliberately not an [_AlarmBanner]-style red/sound/haptic escalation —
/// losing Hub comms must read as "can't verify," not "the boat is
/// dragging," or it becomes exactly the false alarm this was built to
/// avoid.
class _NoFixWarningBanner extends StatelessWidget {
  final PredictWindHubConnectionState? hubState;
  const _NoFixWarningBanner({required this.hubState});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final reason = switch (hubState) {
      null => 'Checking the PredictWind Hub…',
      PredictWindHubConnectionState.connected =>
        'Connected to the Hub, but no live GPS fix — instruments may be '
            'off, or the last reading is stale.',
      _ => "Lost connection to the PredictWind Hub — can't verify the "
          'anchor position.',
    };

    return Card(
      color: theme.colorScheme.tertiaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.gps_off, color: theme.colorScheme.onTertiaryContainer, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Anchor position unknown',
                    style: TextStyle(
                      color: theme.colorScheme.onTertiaryContainer,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    reason,
                    style: TextStyle(color: theme.colorScheme.onTertiaryContainer),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
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
            ? const Text('Requires a connected boat instrument source.')
            : Text(
                'True wind, from '
                '${boatData!.sourceLabel ?? (boatData!.viaLocalNetwork ? 'local network' : 'internet')}',
              ),
      ),
    );
  }
}
