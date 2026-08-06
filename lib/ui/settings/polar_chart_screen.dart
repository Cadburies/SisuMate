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
import '../../services/polar_sample_eligibility.dart';
import '../components/title_tile.dart';

/// #276 — polar diagram: fill-in progress, per-sea-state curves, live sea state.
class PolarChartScreen extends ConsumerStatefulWidget {
  const PolarChartScreen({super.key});

  @override
  ConsumerState<PolarChartScreen> createState() => _PolarChartScreenState();
}

class _PolarChartScreenState extends ConsumerState<PolarChartScreen> {
  bool _improving = false;
  bool _resetting = false;
  bool _refreshingLive = false;
  String? _status;
  Map<String, int> _counts = {};
  SeaState _liveSea = SeaState.unknown;
  PolarLogFieldSnapshot _logFields = PolarLogFieldSnapshot.empty;
  /// Which TWS (kt) curve set to emphasize; null = overlay all common.
  double? _focusTws;
  Timer? _livePoll;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _refreshMeta());
    // Same instrument path as the background collector — refresh while open.
    _livePoll = Timer.periodic(
      const Duration(seconds: 15),
      (_) => unawaited(_refreshMeta()),
    );
  }

  @override
  void dispose() {
    _livePoll?.cancel();
    super.dispose();
  }

  Future<void> _refreshMeta() async {
    if (_refreshingLive) return;
    _refreshingLive = true;
    try {
      final boat = ref.read(activeBoatProvider).asData?.value;
      if (boat == null || boat.supabaseId.isEmpty) {
        if (!mounted) return;
        setState(() {
          _logFields = PolarLogFieldSnapshot.empty;
          _counts = {};
          _liveSea = SeaState.unknown;
        });
        return;
      }
      final collector = ref.read(sailingPolarCollectorProvider);
      final counts = await collector.sampleCountsBySeaState(boat.supabaseId);

      // Live instrument snapshot → same fields the sample row would store.
      PolarLogFieldSnapshot fields = PolarLogFieldSnapshot.empty;
      try {
        final settings = await ref.read(userSettingsProvider.future);
        if (settings != null) {
          const failover = BoatInstrumentFailoverService();
          final snap = await failover.fetch(settings: settings);
          final data = snap.boatData;
          if (data != null) {
            // Keep sea-state window warm even when not fully eligible.
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

      if (!mounted) return;
      setState(() {
        _counts = counts;
        _liveSea = collector.currentSeaState;
        _logFields = fields;
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

    return Scaffold(
      backgroundColor: SisuColors.getAppBackground(isDark),
      body: SafeArea(
        child: Column(
          children: [
            const TitleTile(title: 'Polar diagram'),
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
                        style: TextStyle(
                          color: SisuColors.getTextSecondaryColor(isDark),
                        ),
                      ),
                    );
                  }
                  return _body(context, isDark, boat);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _body(BuildContext context, bool isDark, Boat boat) {
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

    return RefreshIndicator(
      onRefresh: _refreshMeta,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          _liveSeaChip(isDark),
          const SizedBox(height: 12),
          Text(
            'Curves fill in from under-sail samples (instruments online, '
            'engines not showing revs). Smooth seas get the target polar; '
            'rough seas build a separate, lower curve — that is why you often '
            'cannot match the polar in chop.',
            style: TextStyle(
              color: SisuColors.getTextSecondaryColor(isDark),
              fontSize: 13,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 12),
          _liveLogFieldsCard(isDark),
          const SizedBox(height: 12),
          _sampleCountsRow(isDark),
          const SizedBox(height: 12),
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
          DecoratedBox(
            decoration: BoxDecoration(
              color: SisuColors.getTileColor(isDark),
              borderRadius: BorderRadius.circular(12),
              boxShadow: SisuColors.tileElevation(isDark),
            ),
            child: AspectRatio(
              aspectRatio: 1,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: CustomPaint(
                  painter: _PolarDiagramPainter(
                    curvesBySea: curves,
                    focusTws: _focusTws,
                    isDark: isDark,
                    gridColor: SisuColors.getTextSecondaryColor(isDark)
                        .withValues(alpha: 0.35),
                    labelColor: SisuColors.getTextSecondaryColor(isDark),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          _legend(isDark, curves),
          const SizedBox(height: 16),
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

/// Half-polar diagram: TWA 0° at top, 180° at bottom; radius = boat speed.
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
    final center = Offset(size.width / 2, size.height * 0.08);
    final maxR = math.min(size.width / 2 - 16, size.height * 0.88);

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

    // Speed rings
    for (var kn = 2.0; kn <= maxSpeed; kn += 2) {
      final r = maxR * (kn / maxSpeed);
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: r),
        -math.pi / 2,
        math.pi,
        false,
        gridPaint,
      );
    }

    // TWA rays every 30°
    for (var twa = 0.0; twa <= 180.0; twa += 30) {
      final a = _angleForTwa(twa);
      final end = center + Offset(math.cos(a), math.sin(a)) * maxR;
      canvas.drawLine(center, end, gridPaint);
    }

    // Labels: 0 / 90 / 180
    final tp = TextPainter(textDirection: TextDirection.ltr);
    void label(String s, Offset o) {
      tp.text = TextSpan(
        text: s,
        style: TextStyle(color: labelColor, fontSize: 10),
      );
      tp.layout();
      tp.paint(canvas, o - Offset(tp.width / 2, tp.height / 2));
    }

    label('0°', center + const Offset(0, -10));
    label('90°', center + Offset(maxR + 14, 0));
    label('180°', center + Offset(0, maxR + 12));
    label('${maxSpeed.toStringAsFixed(0)} kn', center + Offset(-maxR * 0.55, maxR * 0.55));

    // Draw curves: for each sea state, group by TWS and draw
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
        if (sorted.length < 2) {
          if (sorted.length == 1) {
            final p = sorted.first;
            final pos = _point(center, maxR, maxSpeed, p);
            canvas.drawCircle(
              pos,
              3.5,
              Paint()..color = color,
            );
          }
          continue;
        }
        final path = Path();
        for (var i = 0; i < sorted.length; i++) {
          final pos = _point(center, maxR, maxSpeed, sorted[i]);
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
            _point(center, maxR, maxSpeed, p),
            2.5,
            Paint()..color = color,
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
          size.height * 0.45,
        ),
      );
    }
  }

  /// 0° TWA = up; 180° = down; angles clockwise to starboard.
  double _angleForTwa(double twaDeg) {
    final t = polarNormalizeTwa(twaDeg);
    // Screen: -pi/2 is up; increase clockwise.
    return -math.pi / 2 + (t / 180.0) * math.pi;
  }

  Offset _point(
    Offset center,
    double maxR,
    double maxSpeed,
    PolarPoint p,
  ) {
    final a = _angleForTwa(p.twaDeg);
    final r = maxR * (p.boatSpeedKt / maxSpeed).clamp(0.0, 1.0);
    return center + Offset(math.cos(a), math.sin(a)) * r;
  }

  @override
  bool shouldRepaint(covariant _PolarDiagramPainter old) =>
      old.curvesBySea != curvesBySea ||
      old.focusTws != focusTws ||
      old.isDark != isDark;
}
