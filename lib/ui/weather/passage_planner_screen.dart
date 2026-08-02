import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../core/colors.dart';
import '../../core/units.dart';
import '../../services/weather_service.dart';
import 'passage_weather_briefing_dialog.dart';

class _Wp {
  String name;
  double lat;
  double lon;
  _Wp(this.name, this.lat, this.lon);
}

/// Simple multi-waypoint passage plan: NM, ETA hours, fuel (S3 + SUG3 imperial).
class PassagePlannerScreen extends ConsumerStatefulWidget {
  final double? initialLat;
  final double? initialLon;

  const PassagePlannerScreen({
    super.key,
    this.initialLat,
    this.initialLon,
  });

  @override
  ConsumerState<PassagePlannerScreen> createState() =>
      _PassagePlannerScreenState();
}

class _PassagePlannerScreenState extends ConsumerState<PassagePlannerScreen> {
  final _speedCtrl = TextEditingController(text: '6');
  final _burnCtrl = TextEditingController(text: '4');
  late final List<_Wp> _wps;
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
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Waypoints',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: SisuColors.getTextPrimaryColor(isDark),
            ),
          ),
          const SizedBox(height: 6),
          for (var i = 0; i < _wps.length; i++)
            _wpEditor(i, isDark),
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

  Widget _wpEditor(int i, bool isDark) {
    final w = _wps[i];
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
          ],
        ),
      ),
    );
  }
}
