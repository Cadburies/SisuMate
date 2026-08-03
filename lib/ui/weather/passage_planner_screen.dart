import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

import '../../core/colors.dart';
import '../../core/units.dart';
import '../../models/models.dart' show PolarPoint;
import '../../providers/shopping_provider.dart' show activeBoatProvider;
import '../../services/boat_polar_service.dart';
import '../../services/weather_routing_service.dart';
import '../../services/weather_service.dart';
import 'passage_weather_briefing_dialog.dart';

class _Wp {
  String name;
  double lat;
  double lon;
  _Wp(this.name, this.lat, this.lon);
}

/// #237: cumulative distance (NM) from the first waypoint to [index],
/// summing each leg via the same [haversineNm] `planPassage` already uses.
double cumulativeNmToWaypoint(List<({double lat, double lon})> waypoints, int index) {
  var nm = 0.0;
  for (var i = 1; i <= index && i < waypoints.length; i++) {
    nm += haversineNm(
      waypoints[i - 1].lat,
      waypoints[i - 1].lon,
      waypoints[i].lat,
      waypoints[i].lon,
    );
  }
  return nm;
}

/// #237: matches a waypoint's ETA to the closest available hourly forecast
/// entry. Returns null when nothing in [hourly] is within [maxDrift] of
/// [target] — e.g. the ETA falls beyond Open-Meteo's fetched forecast
/// range (`WeatherBundle.hourly` is capped short of the full 3-day window)
/// — so the caller shows "beyond forecast range" rather than a stale or
/// misleadingly distant match.
HourlyWeather? closestHourlyForEta(
  List<HourlyWeather> hourly,
  DateTime target, {
  Duration maxDrift = const Duration(minutes: 30),
}) {
  HourlyWeather? best;
  Duration? bestDiff;
  for (final h in hourly) {
    final diff = h.time.difference(target).abs();
    if (bestDiff == null || diff < bestDiff) {
      best = h;
      bestDiff = diff;
    }
  }
  if (best == null || bestDiff! > maxDrift) return null;
  return best;
}

/// Simple multi-waypoint passage plan: NM, ETA hours, fuel (S3 + SUG3 imperial).
class PassagePlannerScreen extends ConsumerStatefulWidget {
  final double? initialLat;
  final double? initialLon;
  // #237: injectable for tests — WeatherService.fetch() itself already
  // accepts a client per-call; this just threads a test's MockClient
  // through the widget boundary the same way LocationService is injected
  // elsewhere in the weather module.
  final http.Client? weatherClient;

  const PassagePlannerScreen({
    super.key,
    this.initialLat,
    this.initialLon,
    this.weatherClient,
  });

  @override
  ConsumerState<PassagePlannerScreen> createState() =>
      _PassagePlannerScreenState();
}

class _PassagePlannerScreenState extends ConsumerState<PassagePlannerScreen> {
  final _speedCtrl = TextEditingController(text: '6');
  final _burnCtrl = TextEditingController(text: '4');
  late final List<_Wp> _wps;
  // #237: route-timeline forecast — on-demand only (see _loadRouteForecast),
  // never fetched automatically per waypoint edit/rebuild, since typing in
  // the speed/burn fields would otherwise fire a fetch per keystroke.
  final Map<int, WeatherBundle?> _wpForecasts = {};
  bool _loadingRouteForecast = false;
  // #238: isochrone-routed path, first waypoint to last — user-triggered
  // only (see _computeRoute), additive to the existing great-circle
  // polyline/marker layers, never replacing them.
  IsochroneRoute? _computedRoute;
  bool _computingRoute = false;
  UnitSystem? _lastVolumeSystem;
  SpeedUnitPref? _lastSpeedUnit;

  @override
  void initState() {
    super.initState();
    final lat = widget.initialLat ?? 33.45;
    final lon = widget.initialLon ?? -112.07;
    _wps = [
      _Wp('Departure', lat, lon),
      _Wp('Waypoint 1', lat + 0.3, lon + 0.4),
    ];
  }

  @override
  void dispose() {
    _speedCtrl.dispose();
    _burnCtrl.dispose();
    super.dispose();
  }

  /// Keep burn/speed fields in active display units when prefs change.
  void _syncDisplayFields(AppUnitPrefs prefs) {
    final volume = prefs.volumeSystem;
    if (_lastVolumeSystem != null && _lastVolumeSystem != volume) {
      final raw = double.tryParse(_burnCtrl.text.trim()) ?? 0;
      final liters = UnitConverter.displayVolumeToLiters(raw, _lastVolumeSystem!);
      _burnCtrl.text = UnitConverter.formatNumber(
        UnitConverter.litersToDisplay(liters, volume),
      );
    }
    _lastVolumeSystem = volume;

    final speed = prefs.boatSpeed;
    if (_lastSpeedUnit != null && _lastSpeedUnit != speed) {
      final raw = double.tryParse(_speedCtrl.text.trim()) ?? 0;
      final kn = UnitConverter.speedDisplayToKnots(raw, _lastSpeedUnit!);
      _speedCtrl.text = UnitConverter.formatNumber(
        UnitConverter.knotsToSpeedDisplay(kn, speed),
      );
    }
    _lastSpeedUnit = speed;
  }

  void _addWp() {
    final last = _wps.last;
    setState(() {
      _wps.add(_Wp('Waypoint ${_wps.length}', last.lat + 0.1, last.lon + 0.1));
    });
  }

  /// #237: fetches a forecast per waypoint and stores it for [_wpEditor] to
  /// look up the hour matching that waypoint's ETA. On-demand only — see
  /// [_wpForecasts]'s doc comment for why.
  Future<void> _loadRouteForecast() async {
    final speedDisplay = double.tryParse(_speedCtrl.text) ?? 6;
    final speedKn = UnitConverter.speedDisplayToKnots(
        speedDisplay, ref.read(unitPrefsProvider).boatSpeed);
    if (speedKn <= 0) return;

    setState(() => _loadingRouteForecast = true);
    final service = WeatherService();
    final results = <int, WeatherBundle?>{};
    for (var i = 0; i < _wps.length; i++) {
      try {
        results[i] = await service.fetch(
          lat: _wps[i].lat,
          lon: _wps[i].lon,
          client: widget.weatherClient,
        );
      } catch (_) {
        // Best-effort per waypoint — one failed leg shouldn't blank the rest.
        results[i] = null;
      }
    }
    if (!mounted) return;
    setState(() {
      _wpForecasts
        ..clear()
        ..addAll(results);
      _loadingRouteForecast = false;
    });
  }

  /// #237: the ETA-matched forecast line for waypoint [i], or a clear
  /// "beyond forecast range" note — never a stale/wrong match.
  String? _routeForecastLabel(int i, double speedKn, SpeedUnitPref windUnit) {
    if (!_wpForecasts.containsKey(i)) return null;
    final bundle = _wpForecasts[i];
    if (bundle == null) return 'Forecast unavailable for this waypoint.';
    final waypoints = _wps.map((w) => (lat: w.lat, lon: w.lon)).toList();
    final etaHours =
        speedKn <= 0 ? 0.0 : cumulativeNmToWaypoint(waypoints, i) / speedKn;
    final target = DateTime.now().add(
        Duration(minutes: (etaHours * 60).round()));
    final h = closestHourlyForEta(bundle.hourly, target);
    if (h == null) return 'Beyond forecast range for this waypoint\'s ETA.';
    final wind = h.windMs == null
        ? '-'
        : UnitConverter.formatSpeedFromMs(h.windMs!, windUnit);
    final t = '${h.time.hour.toString().padLeft(2, '0')}:${h.time.minute.toString().padLeft(2, '0')}';
    return 'At ETA ($t): wind $wind, rain ${h.precipProb?.round() ?? '-'}%';
  }

  /// #236: per-leg wind (destination waypoint's ETA-matched hour, same
  /// match #237's route-forecast label uses) for [planPassageWithPolar].
  /// A leg with no fetched forecast, or no hour within tolerance of its
  /// ETA, simply has no entry — that leg falls back to flat speed.
  Map<int, ({double windDirDeg, double windSpeedKt})?> _windByLegIndex(
      double speedKn) {
    final waypoints = _wps.map((w) => (lat: w.lat, lon: w.lon)).toList();
    final map = <int, ({double windDirDeg, double windSpeedKt})?>{};
    for (var i = 1; i < _wps.length; i++) {
      final bundle = _wpForecasts[i];
      if (bundle == null) continue;
      final etaHours =
          speedKn <= 0 ? 0.0 : cumulativeNmToWaypoint(waypoints, i) / speedKn;
      final target =
          DateTime.now().add(Duration(minutes: (etaHours * 60).round()));
      final h = closestHourlyForEta(bundle.hourly, target);
      if (h == null || h.windDirDeg == null || h.windMs == null) continue;
      map[i] = (
        windDirDeg: h.windDirDeg!,
        windSpeedKt: h.windMs! / UnitConverter.msPerKnot,
      );
    }
    return map;
  }

  /// #238: computes an isochrone-routed path from the first to the last
  /// waypoint. v1 uses a single wind sample (the departure waypoint's
  /// current forecast) held constant across the whole route/time window —
  /// explicitly sanctioned by #238's own design notes, since fetching wind
  /// at every candidate isochrone point isn't practical. User-triggered
  /// only, same discipline as [_loadRouteForecast]/[_compareModels]-style
  /// actions elsewhere in the weather module.
  Future<void> _computeRoute() async {
    if (_wps.length < 2) return;
    final polar = ref.read(activeBoatProvider).asData?.value?.polar ??
        const <PolarPoint>[];
    if (polar.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text(
            'Set boat polar data in Settings (Boat Polar Data) first.'),
      ));
      return;
    }

    setState(() => _computingRoute = true);
    try {
      final bundle = await WeatherService().fetch(
        lat: _wps.first.lat,
        lon: _wps.first.lon,
        client: widget.weatherClient,
      );
      final sample = bundle.hourly.isNotEmpty ? bundle.hourly.first : null;
      if (sample?.windDirDeg == null || sample?.windMs == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('No wind data available to compute a route.'),
          ));
        }
        return;
      }
      final windDirDeg = sample!.windDirDeg!;
      final windSpeedKt = sample.windMs! / UnitConverter.msPerKnot;
      final route = computeIsochroneRoute(
        start: (lat: _wps.first.lat, lon: _wps.first.lon),
        end: (lat: _wps.last.lat, lon: _wps.last.lon),
        polar: polar,
        windAt: ({required lat, required lon, required time}) =>
            (windDirDeg: windDirDeg, windSpeedKt: windSpeedKt),
        startTime: DateTime.now(),
      );
      if (!mounted) return;
      setState(() => _computedRoute = route);
      if (route == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text(
              'Could not compute a route with the current polar/wind data.'),
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Route computation failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _computingRoute = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final prefs = ref.watch(unitPrefsProvider);
    _syncDisplayFields(prefs);
    final unitSystem = prefs.volumeSystem;
    final speedDisplay = double.tryParse(_speedCtrl.text) ?? 6;
    final speedKn =
        UnitConverter.speedDisplayToKnots(speedDisplay, prefs.boatSpeed);
    final burnDisplay = double.tryParse(_burnCtrl.text) ?? 4;
    final litersPerHour =
        UnitConverter.displayVolumeToLiters(burnDisplay, unitSystem);
    final plan = planPassage(
      waypoints: _wps.map((w) => (lat: w.lat, lon: w.lon)).toList(),
      speedKn: speedKn,
      litersPerHour: litersPerHour,
    );
    // #236: additive only — the plan above (and its display) is completely
    // unchanged; this just optionally computes a second, clearly-labeled
    // readout when the boat has polar data AND at least one leg has wind
    // data from #237's "Route forecast". No polar data configured (the
    // overwhelmingly common case) means this block never runs.
    final polar = ref.watch(activeBoatProvider).asData?.value?.polar ??
        const <PolarPoint>[];
    final windByLeg = polar.isEmpty
        ? const <int, ({double windDirDeg, double windSpeedKt})?>{}
        : _windByLegIndex(speedKn);
    final hasLegWind = windByLeg.values.any((w) => w != null);
    final polarPlan = (polar.isNotEmpty && hasLegWind)
        ? planPassageWithPolar(
            waypoints: _wps.map((w) => (lat: w.lat, lon: w.lon)).toList(),
            flatSpeedKn: speedKn,
            litersPerHour: litersPerHour,
            polar: polar,
            windByLegIndex: windByLeg,
          )
        : null;
    final fuelLabel = UnitConverter.fuelVolumeLabel(unitSystem);
    final burnLabel = 'Fuel $fuelLabel/h';
    final speedLabel = 'Speed (${UnitConverter.speedUnitLabel(prefs.boatSpeed)})';
    final fuelDisplay = UnitConverter.formatLiters(plan.liters, unitSystem);
    final distanceDisplay =
        UnitConverter.formatDistanceNm(plan.nm, prefs.distance);
    final center = _wps.isEmpty
        ? const LatLng(33.45, -112.07)
        : LatLng(_wps.first.lat, _wps.first.lon);

    return Scaffold(
      backgroundColor: SisuColors.getAppBackground(isDark),
      appBar: AppBar(
        title: const Text('Passage Planner'),
        actions: [
          // #219/#208: distinct purple AI action, never blended with the
          // offline add-waypoint control beside it.
          IconButton(
            icon: const Icon(Icons.auto_awesome, color: Colors.deepPurple),
            tooltip: 'AI: Weather safety briefing',
            onPressed: () => showDialog(
              context: context,
              builder: (_) => const PassageWeatherBriefingDialog(),
            ),
          ),
          IconButton(
            icon: _computingRoute
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.alt_route),
            tooltip: 'Compute isochrone route (needs boat polar data)',
            onPressed: _computingRoute ? null : _computeRoute,
          ),
          IconButton(
            icon: const Icon(Icons.add_location_alt_outlined),
            tooltip: 'Add waypoint',
            onPressed: _addWp,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
        children: [
          SizedBox(
            height: 200,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: FlutterMap(
                options: MapOptions(
                  initialCenter: center,
                  initialZoom: 7,
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.sisumate.app',
                  ),
                  PolylineLayer(
                    polylines: [
                      Polyline(
                        points: _wps.map((w) => LatLng(w.lat, w.lon)).toList(),
                        color: SisuColors.completedBackground,
                        strokeWidth: 3,
                      ),
                      // #238: isochrone-routed path, distinct color from
                      // the great-circle line above — additive, never
                      // replacing it.
                      if (_computedRoute != null)
                        Polyline(
                          points: _computedRoute!.path
                              .map((p) => LatLng(p.lat, p.lon))
                              .toList(),
                          color: Colors.deepOrange,
                          strokeWidth: 3,
                        ),
                    ],
                  ),
                  MarkerLayer(
                    markers: [
                      for (var i = 0; i < _wps.length; i++)
                        Marker(
                          point: LatLng(_wps[i].lat, _wps[i].lon),
                          width: 28,
                          height: 28,
                          child: CircleAvatar(
                            radius: 12,
                            backgroundColor: SisuColors.completedBackground,
                            child: Text(
                              '${i + 1}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Material(
            color: SisuColors.getTileColor(isDark),
            elevation: 2,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Boat',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: SisuColors.getTextPrimaryColor(isDark),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _speedCtrl,
                          decoration: InputDecoration(
                            labelText: speedLabel,
                            isDense: true,
                            border: const OutlineInputBorder(),
                          ),
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _burnCtrl,
                          decoration: InputDecoration(
                            labelText: burnLabel,
                            isDense: true,
                            border: const OutlineInputBorder(),
                          ),
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Summary - Wrap avoids overflow
                  Wrap(
                    spacing: 16,
                    runSpacing: 8,
                    children: [
                      _stat('Distance', distanceDisplay),
                      _stat('ETA', '${plan.hours.toStringAsFixed(1)} h'),
                      _stat('Fuel', fuelDisplay),
                    ],
                  ),
                  if (polarPlan != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Polar-adjusted ETA: ${polarPlan.hours.toStringAsFixed(1)} h '
                      '(uses boat polar + route wind)',
                      style: TextStyle(
                        fontSize: 12,
                        color: SisuColors.getTextSecondaryColor(isDark),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Waypoints',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: SisuColors.getTextPrimaryColor(isDark),
                ),
              ),
              TextButton.icon(
                onPressed: _loadingRouteForecast ? null : _loadRouteForecast,
                icon: _loadingRouteForecast
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.route, size: 18),
                label: const Text('Route forecast'),
              ),
            ],
          ),
          const SizedBox(height: 6),
          for (var i = 0; i < _wps.length; i++)
            _wpEditor(i, isDark, speedKn, prefs.windSpeed),
        ],
      ),
    );
  }

  Widget _stat(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 11)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
      ],
    );
  }

  Widget _wpEditor(int i, bool isDark, double speedKn, SpeedUnitPref windUnit) {
    final w = _wps[i];
    final forecastLabel = _routeForecastLabel(i, speedKn, windUnit);
    return Card(
      color: SisuColors.getTileColor(isDark),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 12,
                  backgroundColor: SisuColors.completedBackground,
                  child: Text(
                    '${i + 1}',
                    style: const TextStyle(color: Colors.white, fontSize: 11),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    initialValue: w.name,
                    decoration: const InputDecoration(
                      labelText: 'Name',
                      isDense: true,
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (v) => w.name = v,
                  ),
                ),
                if (_wps.length > 2)
                  IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () => setState(() => _wps.removeAt(i)),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    initialValue: w.lat.toStringAsFixed(4),
                    decoration: const InputDecoration(
                      labelText: 'Lat',
                      isDense: true,
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                      signed: true,
                    ),
                    onChanged: (v) {
                      final n = double.tryParse(v);
                      if (n != null) {
                        setState(() => w.lat = n);
                      }
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    initialValue: w.lon.toStringAsFixed(4),
                    decoration: const InputDecoration(
                      labelText: 'Lon',
                      isDense: true,
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                      signed: true,
                    ),
                    onChanged: (v) {
                      final n = double.tryParse(v);
                      if (n != null) {
                        setState(() => w.lon = n);
                      }
                    },
                  ),
                ),
              ],
            ),
            if (forecastLabel != null) ...[
              const SizedBox(height: 6),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  forecastLabel,
                  style: TextStyle(
                    fontSize: 12,
                    color: SisuColors.getTextSecondaryColor(isDark),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
