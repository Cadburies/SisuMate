import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/app_router.dart';
import '../../core/colors.dart';
import '../../core/units.dart';
import '../../services/weather_service.dart';
import '../components/title_tile.dart';
import '../components/common_drawer.dart';

/// Weather hub — Open-Meteo forecast + map pin (S3) + device GPS (WX1).
class WeatherScreen extends ConsumerStatefulWidget {
  const WeatherScreen({super.key});

  @override
  ConsumerState<WeatherScreen> createState() => _WeatherScreenState();
}

class _WeatherScreenState extends ConsumerState<WeatherScreen> {
  /// Fallback when GPS is unavailable (Phoenix area - legacy default).
  static const _fallbackLat = 33.4484;
  static const _fallbackLon = -112.0740;

  final _latCtrl = TextEditingController(text: '$_fallbackLat');
  final _lonCtrl = TextEditingController(text: '$_fallbackLon');
  final _placeCtrl = TextEditingController();
  final _service = WeatherService();
  WeatherBundle? _bundle;
  bool _loading = false;
  bool _locating = false;
  bool _searching = false;
  String? _error;
  String? _placeName;
  List<WeatherPlace> _searchHits = const [];
  List<WeatherPlace> _favorites = const [];

  @override
  void initState() {
    super.initState();
    _restoreAndLoad();
  }

  @override
  void dispose() {
    _latCtrl.dispose();
    _lonCtrl.dispose();
    _placeCtrl.dispose();
    super.dispose();
  }

  Future<void> _restoreAndLoad() async {
    final prefs = await SharedPreferences.getInstance();
    final lat = prefs.getDouble('weather_lat');
    final lon = prefs.getDouble('weather_lon');
    final savedName = prefs.getString('weather_place_name');
    final favs = await _service.loadNamedLocations();
    if (mounted) setState(() => _favorites = favs);
    if (lat != null && lon != null) {
      _latCtrl.text = lat.toStringAsFixed(4);
      _lonCtrl.text = lon.toStringAsFixed(4);
      if (savedName != null) _placeName = savedName;
    } else {
      // First launch: try device GPS before fixed inland default (WX1).
      await _useDeviceLocation(silent: true);
    }
    final cached = await _service.loadCache();
    if (cached != null && mounted) {
      setState(() {
        _bundle = cached;
        _placeName = cached.placeName ?? _placeName;
      });
    }
    await _load();
  }

  /// WX1: request permission and fill lat/lon from the device.
  Future<void> _useDeviceLocation({bool silent = false}) async {
    if (_locating) return;
    setState(() => _locating = true);
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (!silent && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Turn on location services to use GPS'),
          ));
        }
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        if (!silent && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text(
                'Location permission denied — enter coordinates or tap the map'),
          ));
        }
        return;
      }

      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 12),
        ),
      );
      if (!mounted) return;
      setState(() {
        _latCtrl.text = pos.latitude.toStringAsFixed(4);
        _lonCtrl.text = pos.longitude.toStringAsFixed(4);
      });
      if (!silent) await _load();
    } catch (e) {
      if (!silent && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Could not get location: $e'),
        ));
      }
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  Future<void> _load({String? placeName}) async {
    final lat = double.tryParse(_latCtrl.text.trim());
    final lon = double.tryParse(_lonCtrl.text.trim());
    if (lat == null || lon == null) {
      setState(() => _error = 'Enter valid latitude and longitude.');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
      _searchHits = const [];
    });
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble('weather_lat', lat);
      await prefs.setDouble('weather_lon', lon);
      final nameHint = placeName ?? _placeName;
      if (nameHint != null && nameHint.isNotEmpty) {
        await prefs.setString('weather_place_name', nameHint);
      }
      final b = await _service.fetch(
        lat: lat,
        lon: lon,
        placeName: nameHint,
      );
      if (!mounted) return;
      setState(() {
        _bundle = b;
        _placeName = b.placeName ?? nameHint;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _searchPlaces() async {
    final q = _placeCtrl.text.trim();
    if (q.length < 2) return;
    setState(() => _searching = true);
    final hits = await _service.searchPlaces(q);
    if (!mounted) return;
    setState(() {
      _searchHits = hits;
      _searching = false;
    });
  }

  Future<void> _selectPlace(WeatherPlace p) async {
    setState(() {
      _latCtrl.text = p.lat.toStringAsFixed(4);
      _lonCtrl.text = p.lon.toStringAsFixed(4);
      _placeName = p.label;
      _placeCtrl.text = p.name;
      _searchHits = const [];
    });
    await _load(placeName: p.label);
  }

  Future<void> _saveFavorite() async {
    final lat = double.tryParse(_latCtrl.text.trim());
    final lon = double.tryParse(_lonCtrl.text.trim());
    if (lat == null || lon == null) return;
    final name = (_placeName ?? _placeCtrl.text).trim();
    if (name.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Name this place first (search or type)')),
      );
      return;
    }
    final list = await _service.addNamedLocation(
      WeatherPlace(name: name, lat: lat, lon: lon),
    );
    if (!mounted) return;
    setState(() => _favorites = list);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Saved "$name"')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final b = _bundle;

    return Scaffold(
      backgroundColor: SisuColors.getAppBackground(isDark),
      endDrawer: Drawer(
        child: ListView(
          children: const [
            DrawerHeaderWidget(title: 'Weather'),
            SectionHeader(title: 'Account'),
            AccountSection(),
            SectionHeader(title: 'Data'),
            DataManagementSection(),
            SectionHeader(title: 'About'),
            AboutSection(),
            DrawerFooter(),
          ],
        ),
      ),
      body: SafeArea(
        child: Builder(
          builder: (context) => Column(
            children: [
              TitleTile(
                title: 'Weather',
                onMenuPressed: () => Scaffold.of(context).openEndDrawer(),
                actionsBuilder: (color) => [
                  IconButton(
                    icon: Icon(Icons.route, color: color),
                    tooltip: 'Passage planner',
                    onPressed: () => context.push(
                      AppRoutes.passage,
                      extra: {
                        'lat': double.tryParse(_latCtrl.text),
                        'lon': double.tryParse(_lonCtrl.text),
                      },
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      _locating ? Icons.hourglass_top : Icons.my_location,
                      color: color,
                    ),
                    tooltip: 'Use my location',
                    onPressed: (_loading || _locating)
                        ? null
                        : () => _useDeviceLocation(),
                  ),
                  IconButton(
                    icon: Icon(Icons.refresh, color: color),
                    tooltip: 'Refresh',
                    onPressed: _loading ? null : _load,
                  ),
                ],
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(12, 4, 12, 24),
                  children: [
                    _locCard(isDark),
                    const SizedBox(height: 10),
                    SizedBox(
                      height: 180,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: FlutterMap(
                          options: MapOptions(
                            initialCenter: LatLng(
                              double.tryParse(_latCtrl.text) ?? 33.45,
                              double.tryParse(_lonCtrl.text) ?? -112.07,
                            ),
                            initialZoom: 8,
                            onTap: (_, p) {
                              setState(() {
                                _latCtrl.text = p.latitude.toStringAsFixed(4);
                                _lonCtrl.text = p.longitude.toStringAsFixed(4);
                              });
                              _load();
                            },
                          ),
                          children: [
                            TileLayer(
                              urlTemplate:
                                  'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                              userAgentPackageName: 'com.sisumate.app',
                            ),
                            MarkerLayer(
                              markers: [
                                Marker(
                                  point: LatLng(
                                    double.tryParse(_latCtrl.text) ?? 33.45,
                                    double.tryParse(_lonCtrl.text) ?? -112.07,
                                  ),
                                  width: 36,
                                  height: 36,
                                  child: Icon(
                                    Icons.location_on,
                                    color: SisuColors.completedBackground,
                                    size: 36,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (_loading) ...[
                      const SizedBox(height: 16),
                      const Center(child: CircularProgressIndicator()),
                    ],
                    if (_error != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        _error!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ],
                    if (b != null) ...[
                      const SizedBox(height: 12),
                      _currentCard(b, isDark),
                      const SizedBox(height: 12),
                      _sectionTitle('Next 12 hours', isDark),
                      ...b.hourly.take(12).map((h) => _hourRow(h, isDark)),
                      const SizedBox(height: 12),
                      _sectionTitle('Daily', isDark),
                      ...b.daily.map((d) => _dayRow(d, isDark)),
                      if (b.marine.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        _sectionTitle('Waves (next hours)', isDark),
                        ...b.marine.take(8).map((m) => _marineRow(m, isDark)),
                      ],
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _locCard(bool isDark) {
    return Material(
      color: SisuColors.getTileColor(isDark),
      elevation: 2,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // SUG3: named place search
            TextField(
              controller: _placeCtrl,
              decoration: InputDecoration(
                labelText: 'Place name',
                hintText: 'e.g. San Diego, Cabo',
                isDense: true,
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: _searching
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.search),
                  onPressed: _searching ? null : _searchPlaces,
                ),
              ),
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => _searchPlaces(),
            ),
            if (_searchHits.isNotEmpty) ...[
              const SizedBox(height: 6),
              ..._searchHits.map(
                (p) => ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.place_outlined, size: 20),
                  title: Text(
                    p.label,
                    style: TextStyle(
                      color: SisuColors.getTextPrimaryColor(isDark),
                      fontSize: 13,
                    ),
                  ),
                  onTap: () => _selectPlace(p),
                ),
              ),
            ],
            if (_favorites.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                'Saved places',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: SisuColors.getTextSecondaryColor(isDark),
                ),
              ),
              const SizedBox(height: 4),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: [
                  for (final p in _favorites)
                    InputChip(
                      label: Text(p.name, style: const TextStyle(fontSize: 12)),
                      onPressed: () => _selectPlace(p),
                      onDeleted: () async {
                        final list = await _service.removeNamedLocation(p);
                        if (mounted) setState(() => _favorites = list);
                      },
                    ),
                ],
              ),
            ],
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _latCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Latitude',
                      isDense: true,
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                      signed: true,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _lonCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Longitude',
                      isDense: true,
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                      signed: true,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                OutlinedButton.icon(
                  onPressed: (_loading || _locating)
                      ? null
                      : () => _useDeviceLocation(),
                  icon: Icon(
                    _locating ? Icons.hourglass_top : Icons.my_location,
                    size: 18,
                  ),
                  label: Text(_locating ? 'Locating...' : 'Use GPS'),
                ),
                const SizedBox(width: 8),
                IconButton(
                  tooltip: 'Save place',
                  onPressed: _loading ? null : _saveFavorite,
                  icon: const Icon(Icons.bookmark_add_outlined),
                ),
                const Spacer(),
                FilledButton(
                  onPressed: _loading ? null : () => _load(),
                  child: const Text('Get forecast'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _currentCard(WeatherBundle b, bool isDark) {
    // Display only: model is always metric (C, m/s, m).
    final prefs = ref.watch(unitPrefsProvider);
    final units = prefs.volumeSystem;
    final depth = b.depthLabel(units, prefs.depth);
    final place = b.placeName ?? _placeName;
    return Material(
      color: SisuColors.getTileColor(isDark),
      elevation: 2,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (place != null && place.isNotEmpty) ...[
              Text(
                place,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: SisuColors.getTextSecondaryColor(isDark),
                ),
              ),
              const SizedBox(height: 4),
            ],
            Text(
              WeatherBundle.weatherCodeLabel(b.weatherCode),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: SisuColors.getTextPrimaryColor(isDark),
              ),
            ),
            if (b.fromCache)
              Text(
                'Cached · ${b.fetchedAt.toLocal()}',
                style: TextStyle(
                  fontSize: 12,
                  color: SisuColors.getTextSecondaryColor(isDark),
                ),
              ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 16,
              runSpacing: 8,
              children: [
                _metric(
                  'Temp',
                  b.tempC == null
                      ? '-'
                      : UnitConverter.formatTempC(
                          b.tempC!,
                          units,
                          temp: prefs.temperature,
                        ),
                ),
                _metric(
                  'Wind',
                  b.windMs == null
                      ? '-'
                      : UnitConverter.formatSpeedFromMs(
                          b.windMs!,
                          prefs.windSpeed,
                        ),
                ),
                _metric(
                  'Dir',
                  b.windDirDeg == null ? '-' : '${b.windDirDeg!.round()} deg',
                ),
                _metric(
                  'RH',
                  b.humidity == null ? '-' : '${b.humidity!.round()}%',
                ),
              ],
            ),
            if (depth != null) ...[
              const SizedBox(height: 8),
              Text(
                depth,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: SisuColors.getTextPrimaryColor(isDark),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _metric(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 11)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
      ],
    );
  }

  Widget _sectionTitle(String t, bool isDark) => Padding(
        padding: const EdgeInsets.only(bottom: 6, top: 4),
        child: Text(
          t,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: SisuColors.getTextPrimaryColor(isDark),
          ),
        ),
      );

  Widget _hourRow(HourlyWeather h, bool isDark) {
    final prefs = ref.watch(unitPrefsProvider);
    final units = prefs.volumeSystem;
    final t =
        '${h.time.hour.toString().padLeft(2, '0')}:${h.time.minute.toString().padLeft(2, '0')}';
    final wind = h.windMs == null
        ? '-'
        : UnitConverter.formatSpeedFromMs(h.windMs!, prefs.windSpeed);
    final temp = h.tempC == null
        ? '-'
        : UnitConverter.formatTempC(h.tempC!, units, temp: prefs.temperature);
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      title: Text(t,
          style: TextStyle(color: SisuColors.getTextPrimaryColor(isDark))),
      subtitle: Text(
        'Wind $wind · rain ${h.precipProb?.round() ?? '-'}%',
        style: TextStyle(color: SisuColors.getTextSecondaryColor(isDark)),
      ),
      trailing: Text(
        temp,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: SisuColors.getTextPrimaryColor(isDark),
        ),
      ),
    );
  }

  Widget _dayRow(DailyWeather d, bool isDark) {
    final prefs = ref.watch(unitPrefsProvider);
    final units = prefs.volumeSystem;
    final label =
        '${d.date.year}-${d.date.month.toString().padLeft(2, '0')}-${d.date.day.toString().padLeft(2, '0')}';
    final maxWind = d.maxWindMs == null
        ? '-'
        : UnitConverter.formatSpeedFromMs(d.maxWindMs!, prefs.windSpeed);
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      title: Text(label,
          style: TextStyle(color: SisuColors.getTextPrimaryColor(isDark))),
      subtitle: Text(
        '${WeatherBundle.weatherCodeLabel(d.weatherCode)} · max wind $maxWind',
        style: TextStyle(color: SisuColors.getTextSecondaryColor(isDark)),
      ),
      trailing: Text(
        UnitConverter.formatTempCRange(
          d.minC,
          d.maxC,
          units,
          temp: prefs.temperature,
        ),
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: SisuColors.getTextPrimaryColor(isDark),
        ),
      ),
    );
  }

  Widget _marineRow(HourlyMarine m, bool isDark) {
    final prefs = ref.watch(unitPrefsProvider);
    final units = prefs.volumeSystem;
    final t =
        '${m.time.hour.toString().padLeft(2, '0')}:${m.time.minute.toString().padLeft(2, '0')}';
    final hs = m.waveHeightM == null
        ? '-'
        : UnitConverter.formatLengthM(
            m.waveHeightM!,
            units,
            depth: prefs.depth,
          );
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      title: Text(t,
          style: TextStyle(color: SisuColors.getTextPrimaryColor(isDark))),
      subtitle: Text(
        'Hs $hs · period ${m.wavePeriodS?.round() ?? '-'} s'
        '${m.waveDirDeg != null ? ' · dir ${m.waveDirDeg!.round()} deg' : ''}',
        style: TextStyle(color: SisuColors.getTextSecondaryColor(isDark)),
      ),
    );
  }
}
