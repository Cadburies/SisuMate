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
import '../../services/predictwind_datahub_service.dart';
import 'anchor_chart_map.dart';

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
/// GPS/wind come **only** from the PredictWind Hub — deliberately no phone
/// GPS fallback (a phone can be carried off the boat, or just be less
/// accurate than the boat's own instrument; either masks a real drag or
/// invents a false one). When the Hub has no usable fix — not connected,
/// connected but no fix yet, or a stale/frozen reading (the Hub can stay
/// powered and keep answering after the boat's NMEA instruments are
/// switched off) — the screen shows a calm warning instead of a phone
/// position, and the drag/danger-zone alarm simply doesn't evaluate
/// (losing the Hub must never itself read as "the boat dragged").
///
/// The alarm (system sound + haptic, repeating every 2s while triggered)
/// only fires while this screen is open and the app is in the foreground —
/// there is no background/lock-screen service yet (tracked separately;
/// see the issue's Notes on background-execution infrastructure).
class AnchorAlarmScreen extends ConsumerStatefulWidget {
  const AnchorAlarmScreen({
    super.key,
    this.hubService = const PredictWindDatahubService(),
    this.httpClient,
    this.pollInterval = const Duration(seconds: 20),
  });

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

  // True only until the very first fetch completes — after that, refreshes
  // (periodic or manual) update data quietly in place. Swapping the whole
  // body out for a spinner on every refresh (the old behavior) tore down
  // in-progress Slider drags and made editing the anchor position
  // effectively impossible — see #256 follow-up.
  bool _initialLoadDone = false;
  bool _isRefreshing = false;
  PredictWindHubStatus? _hubStatus;
  PredictWindBoatData? _boatData;

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

  // Hub-only — deliberately no phone GPS fallback (see class doc). Null
  // whenever the Hub has no fresh, usable fix, regardless of the reason.
  double? get _boatLat => _boatData?.hasFix ?? false ? _boatData!.latitude : null;
  double? get _boatLon => _boatData?.hasFix ?? false ? _boatData!.longitude : null;

  Future<void> _refresh() async {
    setState(() => _isRefreshing = true);
    final hubStatus =
        await widget.hubService.checkConnection(client: widget.httpClient);
    final boatData =
        await widget.hubService.fetchBoatData(client: widget.httpClient);
    if (!mounted) return;
    setState(() {
      _hubStatus = hubStatus;
      _boatData = boatData;
      _initialLoadDone = true;
      _isRefreshing = false;
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
              Expanded(
                child: !_initialLoadDone
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
                            ] else if (activeWatch != null && !canDrop) ...[
                              _NoFixWarningBanner(hubState: _hubStatus?.state),
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
                              AnchorChartMap(
                                activeWatch: activeWatch,
                                boatLat: _boatLat,
                                boatLon: _boatLon,
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
                            _HubStatusCard(
                              status: _hubStatus,
                              isRefreshing: _isRefreshing,
                              onRefresh: _refresh,
                            ),
                            const SizedBox(height: 12),
                            _PositionCard(boatData: _boatData),
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
            _RadiusEditor(
              label: 'Radius',
              value: _radius,
              sliderMax: _maxSliderRadiusMeters,
              onChanged: (v) => setState(() => _radius = v),
              onCommit: _persist,
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
              _RadiusEditor(
                label: 'Radius',
                value: _radiusMeters,
                sliderMax: _maxSliderRadiusMeters,
                onChanged: (v) => setState(() => _radiusMeters = v),
                onCommit: _persist,
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
  const _RadiusEditor({
    required this.label,
    required this.value,
    required this.sliderMax,
    required this.onChanged,
    required this.onCommit,
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
            onChanged: widget.onChanged,
            onChangeEnd: (_) => widget.onCommit(),
          ),
        ),
        SizedBox(
          width: 72,
          child: TextField(
            controller: _textCtrl,
            focusNode: _textFocus,
            textAlign: TextAlign.end,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              isDense: true,
              suffixText: 'm',
              border: OutlineInputBorder(),
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
  const _HubStatusCard({
    required this.status,
    required this.isRefreshing,
    required this.onRefresh,
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
        trailing: isRefreshing
            ? const Padding(
                padding: EdgeInsets.all(12),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            : IconButton(
                icon: const Icon(Icons.refresh),
                tooltip: 'Refresh',
                onPressed: onRefresh,
              ),
      ),
    );
  }
}

/// #256 follow-up — GPS position, Hub-only (no phone GPS; see the screen's
/// class doc for why). Distinguishes "no data at all" from "the Hub has a
/// reading but it's stale/no-fix" ([PredictWindBoatData.hasFix]), since the
/// latter matters for anchor watch trust even though `boatData` is non-null.
class _PositionCard extends StatelessWidget {
  final PredictWindBoatData? boatData;
  const _PositionCard({required this.boatData});

  @override
  Widget build(BuildContext context) {
    final data = boatData;
    final hasFix = data?.hasFix ?? false;
    final theme = Theme.of(context);

    String title;
    String subtitle;
    if (hasFix) {
      title = '${data!.latitude!.toStringAsFixed(5)}, '
          '${data.longitude!.toStringAsFixed(5)}';
      subtitle = 'Source: PredictWind Hub';
    } else if (data == null) {
      title = 'Position unavailable';
      subtitle = 'PredictWind Hub not connected.';
    } else if (data.isStale()) {
      title = 'Position unavailable';
      subtitle = 'Last Hub reading is stale — instruments may be off.';
    } else {
      title = 'Position unavailable';
      subtitle = 'Connected to the Hub, waiting for a GPS fix.';
    }

    return Card(
      child: ListTile(
        leading: Icon(
          hasFix ? Icons.gps_fixed : Icons.gps_off,
          color: hasFix ? null : theme.colorScheme.outline,
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
            ? const Text('Requires a connected PredictWind Hub.')
            : const Text('True wind, from the PredictWind Hub'),
      ),
    );
  }
}
