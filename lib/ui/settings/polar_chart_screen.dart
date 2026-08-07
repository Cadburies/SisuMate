import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/colors.dart';
import '../../core/di.dart';
import '../../models/models.dart';
import '../../models/sea_state.dart';
import '../../providers/shopping_provider.dart' show activeBoatProvider;
import '../../services/boat_instrument_failover_service.dart';
import '../../services/imu_heave_estimator.dart';
import '../../services/polar_bucket_aggregator.dart';
import '../../services/polar_sample_eligibility.dart';
import '../components/title_tile.dart';

/// #276/#281 — polar diagram with tabs: Diagram · Boat · Sea state.
class PolarChartScreen extends ConsumerStatefulWidget {
  const PolarChartScreen({super.key});

  @override
  ConsumerState<PolarChartScreen> createState() => _PolarChartScreenState();
}

class _PolarChartScreenState extends ConsumerState<PolarChartScreen>
    with SingleTickerProviderStateMixin {
  bool _improving = false;
  bool _resetting = false;
  bool _refreshingLive = false;
  String? _status;
  Map<String, int> _counts = {};
  /// #292 — TWA×TWS fill fraction from measured samples (0–1).
  double _coverageFraction = 0;
  int _sampleTotal = 0;
  SeaState _liveSea = SeaState.unknown;
  ImuSeaStateEstimate _imuEstimate = ImuSeaStateEstimate.empty;
  PolarLogFieldSnapshot _logFields = PolarLogFieldSnapshot.empty;
  /// Which TWS (kt) curve set to emphasize; null = overlay all common.
  double? _focusTws;
  Timer? _livePoll;
  /// Instrument hub is polled less often than IMU (expensive / WiFi).
  int _pollTick = 0;
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    // Ensure phone IMU is sampling while this screen is open.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(imuSeaStateServiceProvider).start();
      unawaited(_refreshMeta(fetchInstruments: true));
    });
    // IMU every 3s; boat instruments every ~15s.
    _livePoll = Timer.periodic(const Duration(seconds: 3), (_) {
      _pollTick++;
      unawaited(_refreshMeta(fetchInstruments: _pollTick % 5 == 0));
    });
  }

  @override
  void dispose() {
    _livePoll?.cancel();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _refreshMeta({bool fetchInstruments = true}) async {
    if (_refreshingLive) return;
    _refreshingLive = true;
    try {
      final boat = ref.read(activeBoatProvider).asData?.value;
      final imu = ref.read(imuSeaStateServiceProvider);
      imu.start();
      final imuEst = imu.currentEstimate;

      if (boat == null || boat.supabaseId.isEmpty) {
        if (!mounted) return;
        setState(() {
          _logFields = PolarLogFieldSnapshot.empty;
          _counts = {};
          _coverageFraction = 0;
          _sampleTotal = 0;
          _liveSea = SeaState.unknown;
          _imuEstimate = imuEst;
        });
        return;
      }
      final collector = ref.read(sailingPolarCollectorProvider);
      final counts = await collector.sampleCountsBySeaState(boat.supabaseId);
      // #292 — coverage + improve-hint inputs (bounded sample list).
      final recent = await collector.recent(boat.supabaseId, limit: 2000);
      final coverage = PolarBucketAggregator.coverageFraction(recent);

      PolarLogFieldSnapshot fields = _logFields;
      if (fetchInstruments) {
        // Live instrument snapshot → same fields the sample row would store.
        fields = PolarLogFieldSnapshot.empty;
        try {
          final settings = await ref.read(userSettingsProvider.future);
          if (settings != null) {
            const failover = BoatInstrumentFailoverService();
            final snap = await failover.fetch(settings: settings);
            final data = snap.boatData;
            if (data != null) {
              final preferred = PolarSampleEligibility.preferredBoatSpeed(
                stwKt: data.stwKt,
                sogKt: data.sogKt,
              );
              final cog = data.cogDeg;
              final twd = data.windDirectionDeg;
              final tws = data.windSpeedKt;
              if (preferred != null &&
                  cog != null &&
                  twd != null &&
                  tws != null) {
                collector.observeForSeaState(
                  boatSupabaseId: boat.supabaseId,
                  boatSpeedKt: preferred.speed,
                  twaDeg: PolarSampleEligibility.absoluteTwaDeg(cog, twd),
                  twsKt: tws,
                  sogKt: data.sogKt,
                  stwKt: data.stwKt,
                  at: data.observedAt,
                );
              }
            }
            final metrics = collector.lastMetrics;
            fields = PolarSampleEligibility.logFieldSnapshot(
              data: data,
              boatSupabaseId: boat.supabaseId,
              seaState: collector.currentSeaState,
              speedCv: metrics?.speedCv,
              twaStdDeg: metrics?.twaStdDeg,
              instrumentSummary: snap.summary,
            );
          } else {
            fields = PolarSampleEligibility.logFieldSnapshot(
              data: null,
              boatSupabaseId: boat.supabaseId,
              seaState: collector.currentSeaState,
              instrumentSummary: 'User settings not loaded',
            );
          }
        } catch (e) {
          fields = PolarSampleEligibility.logFieldSnapshot(
            data: null,
            boatSupabaseId: boat.supabaseId,
            seaState: collector.currentSeaState,
            instrumentSummary: 'Instrument fetch failed: $e',
          );
        }
      }

      if (!mounted) return;
      setState(() {
        _counts = counts;
        _coverageFraction = coverage;
        _sampleTotal = recent.length;
        _liveSea = collector.currentSeaState;
        _logFields = fields;
        _imuEstimate = imuEst;
      });
    } finally {
      _refreshingLive = false;
    }
  }

  Future<void> _improveOffline() async {
    final boat = ref.read(activeBoatProvider).asData?.value;
    if (boat == null) return;
    setState(() {
      _improving = true;
      _status = null;
    });
    final result = await ref
        .read(polarLlmImproveServiceProvider)
        .improve(boat: boat, tryLlm: false, applySpline: true);
    if (!mounted) return;
    setState(() {
      _improving = false;
      _status = result.message;
    });
    ref.invalidate(activeBoatProvider);
    await _refreshMeta();
  }

  Future<void> _confirmReset({
    required Boat boat,
    SeaState? seaState,
  }) async {
    final isAll = seaState == null;
    final title = isAll
        ? 'Reset all polars?'
        : 'Reset ${seaState.label} polar?';
    var deleteSamples = false;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setLocal) {
            return AlertDialog(
              title: Text(title),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isAll
                        ? 'Clears every sea-state curve and the primary '
                            'routing polar.'
                        : 'Clears the ${seaState.label} curve'
                            '${seaState == SeaState.calm ? ' and the primary routing polar (Smooth targets)' : ''}.',
                  ),
                  const SizedBox(height: 12),
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    value: deleteSamples,
                    onChanged: (v) =>
                        setLocal(() => deleteSamples = v ?? false),
                    title: Text(
                      isAll
                          ? 'Also delete all under-sail samples'
                          : 'Also delete ${seaState.label} samples',
                    ),
                    subtitle: const Text(
                      'If kept, Improve offline can rebuild from existing data.',
                    ),
                    controlAffinity: ListTileControlAffinity.leading,
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: SisuColors.notAvailableBackground,
                    foregroundColor: SisuColors.dialogButtonOnColor,
                  ),
                  onPressed: () => Navigator.pop(ctx, true),
                  child: const Text('Reset'),
                ),
              ],
            );
          },
        );
      },
    );
    if (ok != true || !mounted) return;

    setState(() {
      _resetting = true;
      _status = null;
    });
    final svc = ref.read(polarLlmImproveServiceProvider);
    final result = isAll
        ? await svc.resetAll(boat: boat, deleteSamples: deleteSamples)
        : await svc.resetSeaState(
            boat: boat,
            seaState: seaState,
            deleteSamples: deleteSamples,
          );
    if (!mounted) return;
    setState(() {
      _resetting = false;
      _status = result.message;
    });
    ref.invalidate(activeBoatProvider);
    await _refreshMeta();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final boatAsync = ref.watch(activeBoatProvider);
    final primary = SisuColors.getTextPrimaryColor(isDark);
    final secondary = SisuColors.getTextSecondaryColor(isDark);

    return Scaffold(
      backgroundColor: SisuColors.getAppBackground(isDark),
      body: SafeArea(
        child: Column(
          children: [
            const TitleTile(title: 'Polar diagram'),
            // #281 — Diagram · Boat · Sea state
            TabBar(
              controller: _tabController,
              labelColor: primary,
              unselectedLabelColor: secondary,
              indicatorColor: SisuColors.completedBackground,
              tabs: const [
                Tab(icon: Icon(Icons.radar, size: 20), text: 'Diagram'),
                Tab(icon: Icon(Icons.sailing, size: 20), text: 'Boat'),
                Tab(icon: Icon(Icons.waves, size: 20), text: 'Sea state'),
              ],
            ),
            Expanded(
              child: boatAsync.when(
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('Error: $e')),
                data: (boat) {
                  if (boat == null) {
                    return Center(
                      child: Text(
                        'No active boat — set one in Settings.',
                        style: TextStyle(color: secondary),
                      ),
                    );
                  }
                  return TabBarView(
                    controller: _tabController,
                    children: [
                      _diagramTab(isDark, boat),
                      _boatTab(isDark),
                      _seaStateTab(isDark),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Tab 1 — polar chart, TWS filter, improve/reset.
  Widget _diagramTab(bool isDark, Boat boat) {
    final multi = boat.polarBySeaState;
    final hasMulti = multi.isNotEmpty;
    final curves = <String, List<PolarPoint>>{
      if (hasMulti)
        ...multi
      else if (boat.polar.isNotEmpty)
        SeaState.calm.wireValue: boat.polar,
    };

    final twsOptions = <double>{
      for (final pts in curves.values)
        for (final p in pts) p.twsKt,
    }.toList()
      ..sort();

    // #308 — chart (and TWS filter / legend) first; long intro copy below.
    final introCopy = Text(
      'Curves fill in from under-sail samples (instruments online, '
      'engines not showing revs). Smooth seas get the target polar; '
      'rough seas build a separate, lower curve — that is why you often '
      'cannot match the polar in chop.',
      style: TextStyle(
        color: SisuColors.getTextSecondaryColor(isDark),
        fontSize: 13,
        height: 1.35,
      ),
    );

    return RefreshIndicator(
      onRefresh: () => _refreshMeta(fetchInstruments: true),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          if (twsOptions.isNotEmpty) ...[
            Text(
              'True wind speed filter',
              style: TextStyle(
                color: SisuColors.getTextPrimaryColor(isDark),
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ChoiceChip(
                  label: const Text('All TWS'),
                  selected: _focusTws == null,
                  onSelected: (_) => setState(() => _focusTws = null),
                ),
                for (final tws in twsOptions)
                  ChoiceChip(
                    label: Text('${tws.toStringAsFixed(0)} kn'),
                    selected: _focusTws == tws,
                    onSelected: (_) => setState(() => _focusTws = tws),
                  ),
              ],
            ),
            const SizedBox(height: 12),
          ],
          // #316 — clip + expand so the painter fills the tile and never
          // bleeds under legend/intro text below.
          DecoratedBox(
            decoration: BoxDecoration(
              color: SisuColors.getTileColor(isDark),
              borderRadius: BorderRadius.circular(12),
              boxShadow: SisuColors.tileElevation(isDark),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: AspectRatio(
                aspectRatio: 1,
                child: CustomPaint(
                  key: const ValueKey('polar_diagram_paint'),
                  painter: _PolarDiagramPainter(
                    curvesBySea: curves,
                    focusTws: _focusTws,
                    isDark: isDark,
                    gridColor: SisuColors.getTextSecondaryColor(isDark)
                        .withValues(alpha: 0.35),
                    labelColor: SisuColors.getTextSecondaryColor(isDark),
                  ),
                  // Force layout to the AspectRatio constraints (painter
                  // alone prefers Size.zero under loose mins).
                  child: const SizedBox.expand(),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          _legend(isDark, curves),
          const SizedBox(height: 16),
          introCopy,
          const SizedBox(height: 12),
          // #292 — measured-polar coverage + auto improve hint.
          Text(
            'Measured coverage: ${(_coverageFraction * 100).toStringAsFixed(0)}% '
            'of TWA×TWS cells · $_sampleTotal sample${_sampleTotal == 1 ? '' : 's'}',
            style: TextStyle(
              color: SisuColors.getTextSecondaryColor(isDark),
              fontSize: 12,
            ),
          ),
          if (PolarBucketAggregator.shouldSuggestOfflineImprove(
            sampleCount: _sampleTotal,
            coverageFraction: _coverageFraction,
          )) ...[
            const SizedBox(height: 6),
            Text(
              'Enough new samples to Improve offline (outlier clean + smooth).',
              style: TextStyle(
                color: SisuColors.getTextPrimaryColor(isDark),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          const SizedBox(height: 12),
          if (_status != null) ...[
            Text(
              _status!,
              style: TextStyle(
                color: SisuColors.getTextSecondaryColor(isDark),
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 8),
          ],
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed:
                      (_improving || _resetting) ? null : _improveOffline,
                  icon: _improving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.analytics_outlined, size: 18),
                  label: const Text('Improve offline'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Reset polar curves',
            style: TextStyle(
              color: SisuColors.getTextPrimaryColor(isDark),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Clear a sea-state polar without wiping the others. Optionally '
            'delete that sea state’s samples so Improve starts clean.',
            style: TextStyle(
              color: SisuColors.getTextSecondaryColor(isDark),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final sea in SeaState.chartOrder)
                OutlinedButton.icon(
                  onPressed: (_improving || _resetting)
                      ? null
                      : () => _confirmReset(boat: boat, seaState: sea),
                  icon: Icon(
                    Icons.restart_alt,
                    size: 16,
                    color: SisuColors.seaStateLineColor(sea.wireValue),
                  ),
                  label: Text('Reset ${sea.label}'),
                ),
              TextButton.icon(
                onPressed: (_improving || _resetting)
                    ? null
                    : () => _confirmReset(boat: boat),
                icon: _resetting
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(
                        Icons.delete_outline,
                        size: 16,
                        color: SisuColors.notAvailableText,
                      ),
                label: Text(
                  'Reset all',
                  style: TextStyle(color: SisuColors.notAvailableText),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Primary routing polar: ${boat.polar.length} points'
            '${hasMulti ? ' · sea-state curves: ${multi.keys.join(", ")}' : ''}',
            style: TextStyle(
              color: SisuColors.getTextSecondaryColor(isDark),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  /// Tab 2 — live instrument values that would be logged.
  Widget _boatTab(bool isDark) {
    return RefreshIndicator(
      onRefresh: () => _refreshMeta(fetchInstruments: true),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          Text(
            'What the under-sail collector would write from boat instruments '
            '(DataHub / NMEA / failover). Leave instruments online; engines '
            'should not show revs for a sample to be eligible.',
            style: TextStyle(
              color: SisuColors.getTextSecondaryColor(isDark),
              fontSize: 13,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 12),
          _liveLogFieldsCard(isDark),
        ],
      ),
    );
  }

  /// Tab 3 — instrument + phone IMU sea-state diagnostics.
  Widget _seaStateTab(bool isDark) {
    return RefreshIndicator(
      onRefresh: () => _refreshMeta(fetchInstruments: true),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          Text(
            'Sea-state buckets keep Smooth / Moderate / Rough polars separate '
            'so rough water does not pull the target curve down.',
            style: TextStyle(
              color: SisuColors.getTextSecondaryColor(isDark),
              fontSize: 13,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 12),
          _liveSeaChip(isDark),
          const SizedBox(height: 12),
          Text(
            'Samples by sea state',
            style: TextStyle(
              color: SisuColors.getTextPrimaryColor(isDark),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          _sampleCountsRow(isDark),
          const SizedBox(height: 16),
          _imuSuggestedSeaCard(isDark),
        ],
      ),
    );
  }

  Widget _liveSeaChip(bool isDark) {
    final wire = _liveSea.wireValue;
    final bg = SisuColors.seaStateChipBg(wire);
    final fg = SisuColors.dialogButtonOnColor;
    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Icon(Icons.waves, color: fg, size: 22),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Working sea state: ${_liveSea.label}',
                    style: TextStyle(
                      color: fg,
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                  Text(
                    _liveSea.shortHint,
                    style: TextStyle(
                      color: fg.withValues(alpha: 0.9),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Refresh',
              onPressed: _refreshMeta,
              icon: _refreshingLive
                  ? SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: fg,
                      ),
                    )
                  : Icon(Icons.refresh, color: fg),
            ),
          ],
        ),
      ),
    );
  }

  /// #280 — phone IMU suggested sea state (WMO-style Hs bands).
  Widget _imuSuggestedSeaCard(bool isDark) {
    final est = _imuEstimate;
    final sea = est.seaState;
    final primary = SisuColors.getTextPrimaryColor(isDark);
    final secondary = SisuColors.getTextSecondaryColor(isDark);
    final line = est.confident
        ? SisuColors.seaStateLineColor(sea.wireValue)
        : secondary;
    final hs = est.significantWaveHeightM;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: SisuColors.getTileColor(isDark),
        borderRadius: BorderRadius.circular(12),
        boxShadow: SisuColors.tileElevation(isDark),
        border: Border.all(color: line.withValues(alpha: 0.45), width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.phone_android, color: line, size: 22),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Phone IMU suggested sea state',
                    style: TextStyle(
                      color: primary,
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                ),
                if (est.confident)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: SisuColors.seaStateChipBg(sea.wireValue),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      sea.label,
                      style: TextStyle(
                        color: SisuColors.dialogButtonOnColor,
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              est.statusMessage,
              style: TextStyle(
                color: line,
                fontWeight: FontWeight.w600,
                fontSize: 13,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Bands (proxy Hs, boat-relative): '
              'Smooth < ${ImuHeaveEstimator.hsCalmMaxM} m · '
              'Moderate < ${ImuHeaveEstimator.hsModerateMaxM} m · '
              'Rough ≥ ${ImuHeaveEstimator.hsModerateMaxM} m. '
              'Not a calibrated buoy — leave the phone still relative to the hull.',
              style: TextStyle(color: secondary, fontSize: 11, height: 1.3),
            ),
            const SizedBox(height: 12),
            _imuField(
              isDark,
              'Proxy Hs',
              hs == null ? '—' : '${hs.toStringAsFixed(2)} m',
              '4·σ(heave) from leaky double-integrate',
            ),
            _imuField(
              isDark,
              'Residual accel RMS',
              '${est.residualAccelRms.toStringAsFixed(3)} m/s²',
              'High-pass |a|−g window RMS',
            ),
            _imuField(
              isDark,
              'Residual accel p90',
              '${est.residualAccelP90.toStringAsFixed(3)} m/s²',
              'High quantile of |residual|',
            ),
            _imuField(
              isDark,
              'Dominant period',
              est.dominantPeriodS == null
                  ? '—'
                  : '${est.dominantPeriodS!.toStringAsFixed(1)} s',
              'Zero-crossing estimate',
            ),
            _imuField(
              isDark,
              'Window',
              '${est.sampleCount} samples · '
                  '${est.windowSeconds.toStringAsFixed(0)} s',
              null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _imuField(
    bool isDark,
    String label,
    String value,
    String? hint,
  ) {
    final primary = SisuColors.getTextPrimaryColor(isDark);
    final secondary = SisuColors.getTextSecondaryColor(isDark);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InputDecorator(
        key: ValueKey('imu_field_$label'),
        decoration: InputDecoration(
          labelText: label,
          helperText: hint,
          helperMaxLines: 2,
          isDense: true,
          filled: true,
          fillColor: SisuColors.getListSurface(isDark),
          border: const OutlineInputBorder(),
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(color: secondary.withValues(alpha: 0.35)),
          ),
        ),
        child: Text(value, style: TextStyle(color: primary, fontSize: 14)),
      ),
    );
  }

  /// Read-only text fields for every value a polar sample would store.
  Widget _liveLogFieldsCard(bool isDark) {
    final snap = _logFields;
    final ok = snap.wouldAccept;
    final statusColor = ok
        ? SisuColors.completedText
        : SisuColors.getTextSecondaryColor(isDark);
    final primary = SisuColors.getTextPrimaryColor(isDark);
    final secondary = SisuColors.getTextSecondaryColor(isDark);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: SisuColors.getTileColor(isDark),
        borderRadius: BorderRadius.circular(12),
        boxShadow: SisuColors.tileElevation(isDark),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Live sample fields',
              style: TextStyle(
                color: primary,
                fontWeight: FontWeight.w700,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'What the collector would write if this reading is accepted. '
              'Wire sync keeps boat speed, SOG/STW, TWA, TWS, sea state; '
              'COG/TWD/engines stay local.',
              style: TextStyle(color: secondary, fontSize: 12, height: 1.3),
            ),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  ok ? Icons.check_circle_outline : Icons.info_outline,
                  size: 18,
                  color: statusColor,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    snap.statusMessage,
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      height: 1.3,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            for (final field in snap.textFields) ...[
              // Read-only text-field chrome (InputDecorator) — same visual as
              // form fields without allocating controllers each rebuild.
              InputDecorator(
                key: ValueKey('polar_log_${field.label}'),
                decoration: InputDecoration(
                  labelText: field.label,
                  helperText: field.hint,
                  helperMaxLines: 2,
                  isDense: true,
                  filled: true,
                  fillColor: SisuColors.getListSurface(isDark),
                  border: const OutlineInputBorder(),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: secondary.withValues(alpha: 0.35),
                    ),
                  ),
                ),
                child: Text(
                  field.value,
                  style: TextStyle(color: primary, fontSize: 14),
                ),
              ),
              const SizedBox(height: 10),
            ],
          ],
        ),
      ),
    );
  }

  Widget _sampleCountsRow(bool isDark) {
    final tiles = [
      for (final sea in SeaState.chartOrder)
        _countTile(isDark, sea, _counts[sea.wireValue] ?? 0),
      _countTile(
        isDark,
        SeaState.unknown,
        _counts[SeaState.unknown.wireValue] ?? 0,
      ),
    ];
    return Row(
      children: [
        for (var i = 0; i < tiles.length; i++) ...[
          if (i > 0) const SizedBox(width: 8),
          Expanded(child: tiles[i]),
        ],
      ],
    );
  }

  Widget _countTile(bool isDark, SeaState sea, int n) {
    final line = SisuColors.seaStateLineColor(sea.wireValue);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: SisuColors.getTileColor(isDark),
        borderRadius: BorderRadius.circular(8),
        boxShadow: SisuColors.tileElevation(isDark),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
        child: Column(
          children: [
            Text(
              '$n',
              style: TextStyle(
                color: line,
                fontWeight: FontWeight.w800,
                fontSize: 18,
              ),
            ),
            Text(
              sea.label,
              style: TextStyle(
                color: SisuColors.getTextSecondaryColor(isDark),
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _legend(bool isDark, Map<String, List<PolarPoint>> curves) {
    return Wrap(
      spacing: 12,
      runSpacing: 8,
      children: [
        for (final sea in SeaState.chartOrder)
          if (curves.containsKey(sea.wireValue))
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 14,
                  height: 3,
                  color: SisuColors.seaStateLineColor(sea.wireValue),
                ),
                const SizedBox(width: 6),
                Text(
                  '${sea.label} (${curves[sea.wireValue]!.length} pts)',
                  style: TextStyle(
                    color: SisuColors.getTextSecondaryColor(isDark),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
      ],
    );
  }
}

/// Full polar diagram centered in its tile: TWA 0° at top, 180° at bottom;
/// radius = boat speed. Port/starboard mirrored (symmetric polars).
///
/// #316 — previous half-polar used origin near the top of a square tile so
/// curves sat high/off the painted area and could bleed past the tile under
/// following text (no clip + non-filling CustomPaint).
class _PolarDiagramPainter extends CustomPainter {
  final Map<String, List<PolarPoint>> curvesBySea;
  final double? focusTws;
  final bool isDark;
  final Color gridColor;
  final Color labelColor;

  _PolarDiagramPainter({
    required this.curvesBySea,
    required this.focusTws,
    required this.isDark,
    required this.gridColor,
    required this.labelColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    // Hard clip to the paint bounds so nothing escapes the tile.
    canvas.save();
    canvas.clipRect(Offset.zero & size);

    // Inset so TWA/speed labels stay inside the clipped rect.
    const labelPad = 18.0;
    final center = Offset(size.width / 2, size.height / 2);
    final maxR =
        math.min(size.width, size.height) / 2 - labelPad;
    if (maxR <= 4) {
      canvas.restore();
      return;
    }

    double maxSpeed = 8;
    for (final pts in curvesBySea.values) {
      for (final p in pts) {
        if (focusTws != null && (p.twsKt - focusTws!).abs() > 0.6) continue;
        if (p.boatSpeedKt > maxSpeed) maxSpeed = p.boatSpeedKt;
      }
    }
    maxSpeed = (maxSpeed * 1.15).clamp(4.0, 40.0);

    final gridPaint = Paint()
      ..color = gridColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    // Speed rings (full circles)
    for (var kn = 2.0; kn <= maxSpeed; kn += 2) {
      final r = maxR * (kn / maxSpeed);
      canvas.drawCircle(center, r, gridPaint);
    }

    // TWA rays every 30° on both port and starboard
    for (var twa = 0.0; twa <= 180.0; twa += 30) {
      for (final stbd in const [true, false]) {
        // Skip drawing the 0°/180° ray twice.
        if (!stbd && (twa == 0.0 || twa == 180.0)) continue;
        final a = _angleForTwa(twa, starboard: stbd);
        final end = center + Offset(math.cos(a), math.sin(a)) * maxR;
        canvas.drawLine(center, end, gridPaint);
      }
    }

    final tp = TextPainter(textDirection: TextDirection.ltr);
    void label(String s, Offset o) {
      tp.text = TextSpan(
        text: s,
        style: TextStyle(color: labelColor, fontSize: 10),
      );
      tp.layout();
      // Keep label fully inside [0, size].
      final dx = (o.dx - tp.width / 2).clamp(2.0, size.width - tp.width - 2);
      final dy =
          (o.dy - tp.height / 2).clamp(2.0, size.height - tp.height - 2);
      tp.paint(canvas, Offset(dx, dy));
    }

    label('0°', center + Offset(0, -maxR - 2));
    label('90°', center + Offset(maxR + 2, 0));
    label('180°', center + Offset(0, maxR + 2));
    label('90° P', center + Offset(-maxR - 2, 0));
    label(
      '${maxSpeed.toStringAsFixed(0)} kn',
      center + Offset(maxR * 0.55, maxR * 0.55),
    );

    // Curves: each sea state, group by TWS; mirror port/starboard.
    for (final sea in SeaState.chartOrder) {
      final pts = curvesBySea[sea.wireValue];
      if (pts == null || pts.isEmpty) continue;
      final color = SisuColors.seaStateLineColor(sea.wireValue);
      final byTws = <double, List<PolarPoint>>{};
      for (final p in pts) {
        if (focusTws != null && (p.twsKt - focusTws!).abs() > 0.6) continue;
        byTws.putIfAbsent(p.twsKt, () => []).add(p);
      }
      for (final group in byTws.values) {
        final sorted = [...group]
          ..sort((a, b) => polarNormalizeTwa(a.twaDeg)
              .compareTo(polarNormalizeTwa(b.twaDeg)));
        for (final stbd in const [true, false]) {
          _drawCurveSide(
            canvas: canvas,
            sorted: sorted,
            center: center,
            maxR: maxR,
            maxSpeed: maxSpeed,
            color: color,
            starboard: stbd,
          );
        }
      }
    }

    if (curvesBySea.isEmpty) {
      tp.text = TextSpan(
        text: 'No polar points yet\nSail + Improve offline',
        style: TextStyle(color: labelColor, fontSize: 13),
      );
      tp.layout(maxWidth: size.width * 0.7);
      tp.paint(
        canvas,
        Offset(
          (size.width - tp.width) / 2,
          (size.height - tp.height) / 2,
        ),
      );
    }

    canvas.restore();
  }

  void _drawCurveSide({
    required Canvas canvas,
    required List<PolarPoint> sorted,
    required Offset center,
    required double maxR,
    required double maxSpeed,
    required Color color,
    required bool starboard,
  }) {
    if (sorted.isEmpty) return;
    if (sorted.length == 1) {
      canvas.drawCircle(
        _point(center, maxR, maxSpeed, sorted.first, starboard: starboard),
        3.5,
        Paint()..color = color,
      );
      return;
    }
    final path = Path();
    for (var i = 0; i < sorted.length; i++) {
      final pos =
          _point(center, maxR, maxSpeed, sorted[i], starboard: starboard);
      if (i == 0) {
        path.moveTo(pos.dx, pos.dy);
      } else {
        path.lineTo(pos.dx, pos.dy);
      }
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2
        ..strokeJoin = StrokeJoin.round,
    );
    for (final p in sorted) {
      canvas.drawCircle(
        _point(center, maxR, maxSpeed, p, starboard: starboard),
        2.5,
        Paint()..color = color,
      );
    }
  }

  /// 0° TWA = up; 180° = down; starboard clockwise, port counter-clockwise.
  double _angleForTwa(double twaDeg, {required bool starboard}) {
    final t = polarNormalizeTwa(twaDeg);
    final signed = starboard ? t : -t;
    return -math.pi / 2 + (signed / 180.0) * math.pi;
  }

  Offset _point(
    Offset center,
    double maxR,
    double maxSpeed,
    PolarPoint p, {
    required bool starboard,
  }) {
    final a = _angleForTwa(p.twaDeg, starboard: starboard);
    final r = maxR * (p.boatSpeedKt / maxSpeed).clamp(0.0, 1.0);
    return center + Offset(math.cos(a), math.sin(a)) * r;
  }

  @override
  bool shouldRepaint(covariant _PolarDiagramPainter old) =>
      old.curvesBySea != curvesBySea ||
      old.focusTws != focusTws ||
      old.isDark != isDark;
}
