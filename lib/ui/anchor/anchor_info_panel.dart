import 'dart:async';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../models/models.dart';
import '../../services/anchor_alarm_service.dart';
import '../../services/predictwind_datahub_service.dart';
import '../../services/tide_service.dart';
import '../../services/weather_service.dart';

/// #266/HA-screen follow-up — read-only instrument snapshot for the Anchor
/// Alarm "Info" tab.
///
/// Order is safety-first: remaining geofence margin and bearing to anchor
/// before raw coordinates. Position may come from phone GPS (#303) when
/// instruments lack a fix — pass [positionLat]/[positionLon] from the parent.
///
/// Tide station + next high/low and the 6-hour forecast are network-backed
/// (NOAA CO-OPS / Open-Meteo, both already used elsewhere in the app) and
/// fetched once a position is available, re-fetched only when the anchor
/// watch changes (a new drop) rather than on every instrument poll — both
/// services cache internally, so this isn't strictly required, but avoids
/// firing a tide-predictions request (uncached) on every ~20s refresh.
class AnchorInfoPanel extends StatefulWidget {
  final AnchorWatch? activeWatch;
  final PredictWindBoatData? boatData;
  /// #303 — best-available boat lat/lon (instruments or phone).
  final double? positionLat;
  final double? positionLon;
  final String? positionSourceLabel;
  /// Test-injection seam for the tide/weather fetches (mirrors
  /// `AnchorAlarmScreen.httpClient`) — real use leaves this null and each
  /// service opens its own client.
  final http.Client? httpClient;

  const AnchorInfoPanel({
    super.key,
    required this.activeWatch,
    required this.boatData,
    this.positionLat,
    this.positionLon,
    this.positionSourceLabel,
    this.httpClient,
  });

  @override
  State<AnchorInfoPanel> createState() => _AnchorInfoPanelState();
}

class _AnchorInfoPanelState extends State<AnchorInfoPanel> {
  static const _alarm = AnchorAlarmService();
  final _tideService = TideService();
  final _weatherService = WeatherService();

  TideStation? _tideStation;
  List<TidePrediction> _tidePredictions = const [];
  List<HourlyWeather> _hourlyForecast = const [];
  bool _loadingTideWeather = false;
  bool _fetchedOnce = false;

  double? get _boatLat =>
      widget.positionLat ??
      ((widget.boatData?.hasFix ?? false) ? widget.boatData!.latitude : null);
  double? get _boatLon =>
      widget.positionLon ??
      ((widget.boatData?.hasFix ?? false) ? widget.boatData!.longitude : null);

  @override
  void initState() {
    super.initState();
    _maybeFetchTideAndWeather();
  }

  @override
  void didUpdateWidget(covariant AnchorInfoPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.activeWatch?.id != widget.activeWatch?.id) {
      _fetchedOnce = false;
    }
    _maybeFetchTideAndWeather();
  }

  void _maybeFetchTideAndWeather() {
    if (_fetchedOnce || _loadingTideWeather) return;
    final lat = _boatLat;
    final lon = _boatLon;
    if (lat == null || lon == null) return;
    _fetchedOnce = true;
    unawaited(_fetchTideAndWeather(lat, lon));
  }

  Future<void> _fetchTideAndWeather(double lat, double lon) async {
    setState(() => _loadingTideWeather = true);
    try {
      final stations =
          await _tideService.fetchTideStations(client: widget.httpClient);
      final station = nearestStation(stations, lat, lon);
      var predictions = const <TidePrediction>[];
      if (station != null) {
        predictions = await _tideService.fetchTidePredictions(
          stationId: station.id,
          client: widget.httpClient,
        );
      }
      final weather = await _weatherService.fetch(
        lat: lat,
        lon: lon,
        client: widget.httpClient,
      );
      if (!mounted) return;
      setState(() {
        _tideStation = station;
        _tidePredictions = predictions;
        _hourlyForecast = weather.hourly.take(6).toList();
        _loadingTideWeather = false;
      });
    } catch (_) {
      // Best-effort — tide/weather are enrichment, not safety-critical
      // like the geofence/bearing metrics above them. A failed fetch just
      // leaves those cards showing "Unavailable".
      if (mounted) setState(() => _loadingTideWeather = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final watch = widget.activeWatch;
    final data = widget.boatData;
    final boatLat = _boatLat;
    final boatLon = _boatLon;
    final hasPos = boatLat != null && boatLon != null;

    double? distFromAnchor;
    double? marginToPerimeter;
    double? bearingToAnchor;
    if (watch != null && boatLat != null && boatLon != null) {
      distFromAnchor = _alarm.distanceMeters(
        lat1: watch.anchorLat,
        lon1: watch.anchorLon,
        lat2: boatLat,
        lon2: boatLon,
      );
      marginToPerimeter = _alarm.distanceFromPerimeterMeters(
        distanceFromAnchorMeters: distFromAnchor,
        radiusMeters: watch.radiusMeters,
      );
      bearingToAnchor = _alarm.bearingToAnchorDeg(
        boatLat: boatLat,
        boatLon: boatLon,
        anchorLat: watch.anchorLat,
        anchorLon: watch.anchorLon,
      );
    }

    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        if (watch == null)
          const Card(
            child: ListTile(
              leading: Icon(Icons.info_outline),
              title: Text('No anchor set'),
              subtitle: Text(
                'Drop an anchor on the Watch tab to see distances and '
                'bearing here.',
              ),
            ),
          )
        else ...[
          _metricCard(
            context,
            icon: Icons.radar,
            title: 'Margin to perimeter',
            value: marginToPerimeter == null
                ? 'Unavailable'
                : marginToPerimeter >= 0
                    ? '${marginToPerimeter.toStringAsFixed(0)} m remaining'
                    : '${(-marginToPerimeter).toStringAsFixed(0)} m past circle',
            subtitle: marginToPerimeter == null
                ? 'Needs a live boat position (instruments or phone GPS).'
                : marginToPerimeter >= 0
                    ? 'Still inside the ${watch.radiusMeters.toStringAsFixed(0)} m alarm circle.'
                    : 'Outside the safe swinging circle.',
            emphasis: marginToPerimeter != null && marginToPerimeter < 0,
          ),
          _metricCard(
            context,
            icon: Icons.navigation,
            title: 'Bearing to anchor',
            value: bearingToAnchor == null
                ? 'Unavailable'
                : '${bearingToAnchor.toStringAsFixed(0)}°T',
            subtitle: 'Direction from the boat back to the anchor.',
          ),
          _metricCard(
            context,
            icon: Icons.straighten,
            title: 'Distance from anchor',
            value: distFromAnchor == null
                ? 'Unavailable'
                : '${distFromAnchor.toStringAsFixed(0)} m',
          ),
        ],
        // #305 — depth is independent of GPS fix (sounder can stream without a fix).
        _metricCard(
          context,
          icon: Icons.waves,
          title: 'Depth',
          value: data?.depthMeters == null
              ? 'Unavailable'
              : '${data!.depthMeters!.toStringAsFixed(1)} m',
          subtitle: data?.depthMeters == null
              ? 'Needs a depth reading from boat instruments.'
              : 'Water depth below transducer (instruments)',
        ),
        _metricCard(
          context,
          icon: Icons.thermostat,
          title: 'Air temperature',
          value: data?.airTempC == null
              ? 'Unavailable'
              : '${data!.airTempC!.toStringAsFixed(1)}°C',
          subtitle: 'From boat instruments (NMEA).',
        ),
        _metricCard(
          context,
          icon: Icons.thermostat_outlined,
          title: 'Water temperature',
          value: data?.waterTempC == null
              ? 'Unavailable'
              : '${data!.waterTempC!.toStringAsFixed(1)}°C',
          subtitle: 'From boat instruments (NMEA).',
        ),
        _metricCard(
          context,
          icon: Icons.speed,
          title: 'SOG',
          value: data?.sogKt == null
              ? 'Unavailable'
              : '${data!.sogKt!.toStringAsFixed(1)} kn',
          subtitle: 'Speed over ground',
        ),
        _metricCard(
          context,
          icon: Icons.explore,
          title: 'COG',
          value: data?.cogDeg == null
              ? 'Unavailable'
              : '${data!.cogDeg!.toStringAsFixed(0)}°T',
          subtitle: 'Course over ground',
        ),
        _metricCard(
          context,
          icon: Icons.air,
          title: 'Apparent wind',
          value: data?.apparentWindSpeedKt == null
              ? 'Unavailable'
              : data!.apparentWindDirectionDeg != null
                  ? '${data.apparentWindSpeedKt!.toStringAsFixed(1)} kn @ '
                      '${data.apparentWindDirectionDeg!.toStringAsFixed(0)}°'
                  : '${data.apparentWindSpeedKt!.toStringAsFixed(1)} kn',
          subtitle: 'AWS / AWA from the Hub',
        ),
        _metricCard(
          context,
          icon: Icons.gps_fixed,
          title: 'Boat GPS',
          value: hasPos
              ? '${boatLat.toStringAsFixed(5)}, ${boatLon.toStringAsFixed(5)}'
              : 'Unavailable',
          subtitle: hasPos
              ? 'Source: ${widget.positionSourceLabel ?? data?.sourceLabel ?? 'Unknown'}'
              : 'Waiting for instruments or phone GPS.',
        ),
        if (watch != null)
          _metricCard(
            context,
            icon: Icons.anchor,
            title: 'Anchor GPS',
            value:
                '${watch.anchorLat.toStringAsFixed(5)}, ${watch.anchorLon.toStringAsFixed(5)}',
            subtitle:
                'Alarm radius ${watch.radiusMeters.toStringAsFixed(0)} m',
          ),
        if (hasPos) ...[
          const SizedBox(height: 4),
          _tideCard(context),
          _forecastCard(context),
        ],
      ],
    );
  }

  Widget _tideCard(BuildContext context) {
    final station = _tideStation;
    if (_loadingTideWeather && station == null) {
      return _metricCard(
        context,
        icon: Icons.waves,
        title: 'Nearest tide station',
        value: 'Loading…',
      );
    }
    if (station == null) {
      return _metricCard(
        context,
        icon: Icons.waves,
        title: 'Nearest tide station',
        value: 'Unavailable',
        subtitle: 'No NOAA station within range (US/territories coverage '
            'only) or the lookup failed.',
      );
    }
    final now = DateTime.now();
    final upcoming = _tidePredictions.where((p) => p.time.isAfter(now));
    final nextHigh = upcoming.where((p) => p.type == 'H').firstOrNull;
    final nextLow = upcoming.where((p) => p.type == 'L').firstOrNull;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.waves),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(station.name,
                      style: Theme.of(context).textTheme.titleSmall),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _tideRow(context, label: 'Next high', prediction: nextHigh),
            _tideRow(context, label: 'Next low', prediction: nextLow),
          ],
        ),
      ),
    );
  }

  Widget _tideRow(
    BuildContext context, {
    required String label,
    required TidePrediction? prediction,
  }) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(width: 80, child: Text(label, style: theme.textTheme.bodyMedium)),
          Expanded(
            child: Text(
              prediction == null
                  ? 'Unavailable'
                  : '${_formatTime(prediction.time)} '
                      '(${prediction.heightFt.toStringAsFixed(1)} ft)',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: prediction == null ? theme.colorScheme.outline : null,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _forecastCard(BuildContext context) {
    if (_loadingTideWeather && _hourlyForecast.isEmpty) {
      return _metricCard(
        context,
        icon: Icons.cloud_outlined,
        title: 'Next 6 hours',
        value: 'Loading…',
      );
    }
    if (_hourlyForecast.isEmpty) {
      return _metricCard(
        context,
        icon: Icons.cloud_outlined,
        title: 'Next 6 hours',
        value: 'Unavailable',
        subtitle: 'Forecast fetch failed — check connectivity.',
      );
    }
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.cloud_outlined),
                const SizedBox(width: 12),
                Text('Next 6 hours', style: theme.textTheme.titleSmall),
              ],
            ),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final h in _hourlyForecast) _hourlyColumn(context, h),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _hourlyColumn(BuildContext context, HourlyWeather h) {
    final theme = Theme.of(context);
    return Container(
      width: 64,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        children: [
          Text(_formatHour(h.time), style: theme.textTheme.bodySmall),
          const SizedBox(height: 4),
          Text(
            h.tempC == null ? '—' : '${h.tempC!.toStringAsFixed(0)}°',
            style: theme.textTheme.titleSmall,
          ),
          const SizedBox(height: 2),
          Text(
            h.windMs == null
                ? '—'
                : '${(h.windMs! * 1.943844).toStringAsFixed(0)} kn',
            style: theme.textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  static String _formatTime(DateTime t) {
    final local = t.toLocal();
    final h = local.hour.toString().padLeft(2, '0');
    final m = local.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  static String _formatHour(DateTime t) => _formatTime(t);

  Widget _metricCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String value,
    String? subtitle,
    bool emphasis = false,
  }) {
    final theme = Theme.of(context);
    final unavailable = value == 'Unavailable';
    return Card(
      child: ListTile(
        leading: Icon(
          icon,
          color: emphasis
              ? theme.colorScheme.error
              : unavailable
                  ? theme.colorScheme.outline
                  : null,
        ),
        title: Text(title),
        subtitle: subtitle == null ? null : Text(subtitle),
        trailing: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 160),
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: emphasis
                  ? theme.colorScheme.error
                  : unavailable
                      ? theme.colorScheme.outline
                      : null,
            ),
          ),
        ),
      ),
    );
  }
}
