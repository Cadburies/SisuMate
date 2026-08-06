import 'dart:async';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/app_router.dart';
import '../../core/colors.dart';
import '../../core/units.dart';
import '../../services/error_log_service.dart';
import '../../services/location_service.dart';
import '../../services/map_tile_cache_service.dart';
import '../../services/map_tile_providers.dart';
import '../../services/marine_hazard_service.dart';
import '../../services/tide_service.dart';
import '../../services/weather_service.dart';
import '../components/title_tile.dart';
import '../components/common_drawer.dart';
import 'caching_tile_provider.dart';

/// Weather hub — Open-Meteo forecast + map pin (S3) + device GPS (WX1).
class WeatherScreen extends ConsumerStatefulWidget {
  final LocationService? locationService;

  const WeatherScreen({super.key, this.locationService});

  @override
  ConsumerState<WeatherScreen> createState() => _WeatherScreenState();
}

class _WeatherScreenState extends ConsumerState<WeatherScreen> {
  /// Map seed only (not a forecast location). Used when no GPS/saved pin yet.
  /// Neutral open-ocean start avoids a misleading inland city label (e.g. the
  /// old Phoenix default that stuck after "Use GPS" until reverse-geocode ran).
  static const _mapSeedLat = 0.0;
  static const _mapSeedLon = 0.0;

  final _latCtrl = TextEditingController();
  final _lonCtrl = TextEditingController();
  final _placeCtrl = TextEditingController();
  final _service = WeatherService();
  // #212: MapOptions.initialCenter only applies on first load (flutter_map's
  // own doc comment) — it's not reactive, so a GPS fix or search-selected
  // place moved the marker (rebuilds from _latCtrl/_lonCtrl) but never the
  // map viewport itself without an explicit MapController.move() call.
  final _mapController = MapController();
  // Guards MapController.move() — flutter_map throws if called before
  // FlutterMap has rendered at least once, which can race the silent GPS
  // lookup this screen fires from initState on first launch.
  bool _mapReady = false;
  late final LocationService _locationService =
      widget.locationService ?? const LocationService();
  // #240/#241: multi-provider basemap + tile-download/cache framework.
  final _tileCacheService = MapTileCacheService();
  String _providerId = mapTileBaseProviders.first.id;
  bool _showSeamarks = false;
  bool _prefetching = false;
  String? _cacheFolderOverride;
  WeatherBundle? _bundle;
  // #229: ensemble forecast confidence/spread — fetched alongside the main
  // bundle (same trigger, not a second background poll); best-effort, so a
  // null value here just means no confidence badge shows, never an error.
  EnsembleBundle? _ensembleBundle;
  // #233: multi-model comparison is strictly user-triggered (see
  // _compareModels) — never fetched alongside the regular _load().
  bool _comparingModels = false;
  // #239: marine hazard alerts — fetched alongside the main bundle (same
  // trigger as #229's ensemble, not a second background poll); a single
  // lightweight point query, unlike #234's multi-MB tide station list, so
  // no separate manual gate. Never cached — hazard alerts are time-
  // sensitive; a stale "all clear" from an old cache would be misleading.
  final _marineHazardService = MarineHazardService();
  List<MarineHazardAlert> _hazardAlerts = const [];
  // #234: tide/current predictions — user-triggered (see _loadTideAndCurrent),
  // since the first call fetches a multi-MB NOAA station list.
  final _tideService = TideService();
  TideStation? _tideStation;
  List<TidePrediction> _tidePredictions = const [];
  TideStation? _currentStation;
  List<CurrentPrediction> _currentPredictions = const [];
  bool _loadingTide = false;
  bool _tideLoadAttempted = false;
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
    _mapController.dispose();
    super.dispose();
  }

  /// #212: re-centers the map viewport, not just the marker — no-ops
  /// before the map's first render (see [_mapReady]).
  void _recenterMap(double lat, double lon) {
    if (!_mapReady) return;
    _mapController.move(LatLng(lat, lon), _mapController.camera.zoom);
  }

  Future<void> _restoreAndLoad() async {
    final prefs = await SharedPreferences.getInstance();
    final lat = prefs.getDouble('weather_lat');
    final lon = prefs.getDouble('weather_lon');
    final savedName = prefs.getString('weather_place_name');
    final savedProviderId = prefs.getString(kMapTileProviderIdPrefKey);
    final favs = await _service.loadNamedLocations();
    final cacheFolder = await _tileCacheService.cacheFolderOverride();
    if (mounted) {
      setState(() {
        _favorites = favs;
        if (savedProviderId != null) _providerId = savedProviderId;
        _showSeamarks = prefs.getBool('map_tile_seamarks_overlay') ?? false;
        _cacheFolderOverride = cacheFolder;
      });
    }
    if (lat != null && lon != null) {
      _latCtrl.text = lat.toStringAsFixed(4);
      _lonCtrl.text = lon.toStringAsFixed(4);
      // Only restore a saved name when it matches the saved pin — never apply
      // a stale city label to a new GPS/map pin (that was the Phoenix bug).
      if (savedName != null) _placeName = savedName;
    } else {
      // First launch: try device GPS (no inland city default).
      await _useDeviceLocation(silent: true);
    }
    final cached = await _service.loadCache();
    final cachedEnsemble = await _service.loadEnsembleCache();
    if (cached != null && mounted) {
      final curLat = double.tryParse(_latCtrl.text.trim());
      final curLon = double.tryParse(_lonCtrl.text.trim());
      final cacheMatchesPin = curLat != null &&
          curLon != null &&
          (cached.lat - curLat).abs() < 0.05 &&
          (cached.lon - curLon).abs() < 0.05;
      setState(() {
        if (cacheMatchesPin) {
          _bundle = cached;
          _ensembleBundle = cachedEnsemble;
          _placeName = cached.placeName ?? _placeName;
        }
      });
    }
    final hasCoords = double.tryParse(_latCtrl.text.trim()) != null &&
        double.tryParse(_lonCtrl.text.trim()) != null;
    if (hasCoords) {
      await _load();
    }
  }

  /// WX1: request permission and fill lat/lon from the device.
  Future<void> _useDeviceLocation({bool silent = false}) async {
    if (_locating) return;
    setState(() => _locating = true);
    try {
      final result = await _locationService.getCurrentPosition();
      if (!mounted) return;
      switch (result.failureReason) {
        case LocationFailureReason.serviceDisabled:
          if (!silent) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('Turn on location services to use GPS'),
            ));
          }
          return;
        case LocationFailureReason.permissionDenied:
          if (!silent) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text(
                  'Location permission denied — enter coordinates or tap the map'),
            ));
          }
          return;
        case LocationFailureReason.error:
          // #283 — timeouts / no-fix indoors are expected control flow
          // (SnackBar is enough). Only log unexpected location failures so
          // triage does not file one GitHub issue per slow GPS.
          final err = result.error;
          final msg = err?.toString() ?? '';
          final expectedTimeout = msg.contains('TimeoutException') ||
              msg.contains('time limit') ||
              msg.contains('TIMEOUT');
          if (!expectedTimeout) {
            unawaited(ErrorLogService().logWarning(
              'location lookup failed: $err',
              context: 'weather_screen: _locate',
            ));
          }
          if (!silent) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(
                expectedTimeout
                    ? 'GPS timed out — try outdoors or enter coordinates'
                    : 'Could not get location: $err',
              ),
            ));
          }
          return;
        case null:
          final pos = result.position!;
          // New pin ⇒ drop any previous place label so reverse-geocode runs.
          // (Previously we kept "Phoenix, Maricopa County…" after GPS moved
          // the coords, and WeatherService skipped reverse geocode.)
          setState(() {
            _latCtrl.text = pos.latitude.toStringAsFixed(4);
            _lonCtrl.text = pos.longitude.toStringAsFixed(4);
            _placeName = null;
          });
          final prefs = await SharedPreferences.getInstance();
          await prefs.remove('weather_place_name');
          _recenterMap(pos.latitude, pos.longitude);
          await _load();
      }
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  /// [placeName] only when the user picked a search hit (trust that label).
  /// GPS / map / Get forecast leave it null so reverse-geocode can run when
  /// [_placeName] was cleared for a new pin.
  Future<void> _load({String? placeName}) async {
    final lat = double.tryParse(_latCtrl.text.trim());
    final lon = double.tryParse(_lonCtrl.text.trim());
    if (lat == null || lon == null) {
      setState(() => _error =
          'Set a location — Use GPS, tap the map, search a place, or enter coordinates.');
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
      final effectiveName = placeName ?? _placeName;
      if (effectiveName != null && effectiveName.isNotEmpty) {
        await prefs.setString('weather_place_name', effectiveName);
      } else {
        await prefs.remove('weather_place_name');
      }
      final results = await Future.wait([
        _service.fetch(lat: lat, lon: lon, placeName: effectiveName),
        _service.fetchEnsemble(lat: lat, lon: lon),
        _marineHazardService.fetchActiveAlerts(lat: lat, lon: lon),
      ]);
      final b = results[0] as WeatherBundle;
      final ensemble = results[1] as EnsembleBundle?;
      final hazards = results[2] as List<MarineHazardAlert>;
      if (!mounted) return;
      setState(() {
        _bundle = b;
        _ensembleBundle = ensemble;
        _hazardAlerts = hazards;
        _placeName = b.placeName ?? effectiveName;
        _loading = false;
      });
    } catch (e) {
      unawaited(
          ErrorLogService().logWarning('weather load failed: $e', context: 'weather_screen: _load'));
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  /// #233: strictly user-triggered — never fired from _load()/_restoreAndLoad,
  /// so a normal weather refresh never silently multiplies into N model
  /// requests.
  Future<void> _compareModels() async {
    final lat = double.tryParse(_latCtrl.text.trim());
    final lon = double.tryParse(_lonCtrl.text.trim());
    if (lat == null || lon == null) return;
    setState(() => _comparingModels = true);
    final bundle = await _service.fetchMultiModel(lat: lat, lon: lon);
    if (!mounted) return;
    setState(() => _comparingModels = false);
    if (bundle == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Could not load model comparison — try again.'),
      ));
      return;
    }
    if (!mounted) return;
    final prefs = ref.read(unitPrefsProvider);
    await showDialog<void>(
      context: context,
      builder: (_) => _ModelComparisonDialog(bundle: bundle, speedUnit: prefs.windSpeed),
    );
  }

  /// #234: nearest NOAA tide/current stations + their predictions — the
  /// first call fetches a multi-MB station list (cached ~30 days after),
  /// so this is strictly user-triggered, never part of the regular _load().
  /// No coverage nearby degrades to "no data" (empty station), not an
  /// error — matches the acceptance criterion.
  Future<void> _loadTideAndCurrent() async {
    final lat = double.tryParse(_latCtrl.text.trim());
    final lon = double.tryParse(_lonCtrl.text.trim());
    if (lat == null || lon == null) return;
    setState(() {
      _loadingTide = true;
      _tideLoadAttempted = true;
    });
    try {
      final tideStations = await _tideService.fetchTideStations();
      final tideStation = nearestStation(tideStations, lat, lon);
      final tidePredictions = tideStation == null
          ? const <TidePrediction>[]
          : await _tideService.fetchTidePredictions(stationId: tideStation.id);

      final currentStations = await _tideService.fetchCurrentStations();
      final currentStation = nearestStation(currentStations, lat, lon);
      final currentPredictions = currentStation == null
          ? const <CurrentPrediction>[]
          : await _tideService.fetchCurrentPredictions(
              stationId: currentStation.id);

      if (!mounted) return;
      setState(() {
        _tideStation = tideStation;
        _tidePredictions = tidePredictions;
        _currentStation = currentStation;
        _currentPredictions = currentPredictions;
      });
    } finally {
      if (mounted) setState(() => _loadingTide = false);
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

  void _invalidatePlaceNameForCoordEdit() {
    if (_placeName != null) {
      setState(() => _placeName = null);
    }
  }

  Future<void> _selectPlace(WeatherPlace p) async {
    setState(() {
      _latCtrl.text = p.lat.toStringAsFixed(4);
      _lonCtrl.text = p.lon.toStringAsFixed(4);
      _placeName = p.label;
      _placeCtrl.text = p.name;
      _searchHits = const [];
    });
    _recenterMap(p.lat, p.lon);
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

  void _showProviderPicker(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Basemap'),
        content: SizedBox(
          width: double.maxFinite,
          child: RadioGroup<String>(
            groupValue: _providerId,
            onChanged: (id) {
              if (id != null) _setProvider(id);
              Navigator.of(dialogContext).pop();
            },
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final provider in mapTileBaseProviders)
                  RadioListTile<String>(
                    value: provider.id,
                    title: Text(provider.label),
                    subtitle: provider.usageCaveat != null
                        ? Text(provider.usageCaveat!,
                            style: const TextStyle(fontSize: 11))
                        : null,
                  ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  // #240: basemap/overlay selection, persisted across launches.
  Future<void> _setProvider(String id) async {
    setState(() => _providerId = id);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(kMapTileProviderIdPrefKey, id);
  }

  Future<void> _setSeamarksOverlay(bool value) async {
    setState(() => _showSeamarks = value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('map_tile_seamarks_overlay', value);
  }

  Future<void> _pickCacheFolder() async {
    final path = await FilePicker.platform.getDirectoryPath();
    if (path == null || !mounted) return;
    await _tileCacheService.setCacheFolderOverride(path);
    if (!mounted) return;
    setState(() => _cacheFolderOverride = path);
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text('Tile cache folder set to $path')));
  }

  /// #241: downloads every tile covering the current viewport at the
  /// current zoom for the active provider. Deliberately an explicit
  /// user-triggered action, not automatic-on-pan — silent background
  /// downloading on a boat with limited/metered satellite data could be an
  /// unwelcome surprise.
  Future<void> _downloadTilesForView() async {
    if (!_mapReady || _prefetching) return;
    setState(() => _prefetching = true);
    try {
      final bounds = _mapController.camera.visibleBounds;
      final zoom = _mapController.camera.zoom.round();
      final provider = mapTileProviderById(_providerId);
      final count = await _tileCacheService.prefetchViewport(
        providerId: provider.id,
        urlTemplate: provider.urlTemplate,
        bounds: bounds,
        zoom: zoom,
      );
      if (!mounted) return;
      if (count == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text(
              'Too many tiles in this view to download — zoom in first'),
        ));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content:
              Text('Downloaded $count tile${count == 1 ? '' : 's'} for offline use'),
        ));
      }
    } finally {
      if (mounted) setState(() => _prefetching = false);
    }
  }

  Future<void> _clearTilesForView() async {
    if (!_mapReady) return;
    final bounds = _mapController.camera.visibleBounds;
    final zoom = _mapController.camera.zoom.round();
    final provider = mapTileProviderById(_providerId);
    final count = await _tileCacheService.clearRegion(
      providerId: provider.id,
      bounds: bounds,
      zoom: zoom,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('Cleared $count cached tile${count == 1 ? '' : 's'} for this view'),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final b = _bundle;

    return Scaffold(
      backgroundColor: SisuColors.getAppBackground(isDark),
      endDrawer: Drawer(
        child: ListView(
          children: [
            const DrawerHeaderWidget(title: 'Weather'),
            const SectionHeader(title: 'Map'),
            ListTile(
              leading: const Icon(Icons.layers_outlined),
              title: const Text('Basemap'),
              subtitle: Text(mapTileProviderById(_providerId).label),
              onTap: () => _showProviderPicker(context),
            ),
            SwitchListTile(
              title: const Text('Nautical marks overlay'),
              subtitle: const Text('OpenSeaMap seamarks & buoys'),
              value: _showSeamarks,
              onChanged: _setSeamarksOverlay,
            ),
            ListTile(
              leading: _prefetching
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.download_outlined),
              title: const Text('Download tiles for this view'),
              subtitle: const Text('Caches the visible map area for offline use'),
              onTap: _prefetching ? null : _downloadTilesForView,
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline),
              title: const Text('Clear cached tiles for this view'),
              subtitle: Text('${mapTileProviderById(_providerId).label} only'),
              onTap: _clearTilesForView,
            ),
            ListTile(
              leading: const Icon(Icons.folder_outlined),
              title: const Text('Tile cache folder'),
              subtitle: Text(_cacheFolderOverride ?? 'Default (app cache)'),
              onTap: _pickCacheFolder,
            ),
            const SectionHeader(title: 'Account'),
            const AccountSection(),
            const SectionHeader(title: 'Data'),
            const DataManagementSection(),
            const ProUpgradeSection(),
            const SectionHeader(title: 'About'),
            const AboutSection(),
            const DrawerFooter(),
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
                    icon: Icon(Icons.event_available, color: color),
                    tooltip: 'Departure window planner',
                    onPressed: () => context.push(AppRoutes.departureWindow),
                  ),
                  IconButton(
                    icon: Icon(Icons.grid_on, color: color),
                    tooltip: 'GRIB viewer',
                    onPressed: () => context.push(AppRoutes.gribViewer),
                  ),
                  IconButton(
                    icon: Icon(Icons.cloud_download_outlined, color: color),
                    tooltip: 'Free GRIB download',
                    onPressed: () => context.push(
                      AppRoutes.gribRequest,
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
                          mapController: _mapController,
                          options: MapOptions(
                            initialCenter: LatLng(
                              double.tryParse(_latCtrl.text) ?? _mapSeedLat,
                              double.tryParse(_lonCtrl.text) ?? _mapSeedLon,
                            ),
                            initialZoom: double.tryParse(_latCtrl.text) == null
                                ? 2
                                : 8,
                            onMapReady: () => _mapReady = true,
                            onTap: (_, p) {
                              // New pin from map — drop stale city label.
                              setState(() {
                                _latCtrl.text = p.latitude.toStringAsFixed(4);
                                _lonCtrl.text = p.longitude.toStringAsFixed(4);
                                _placeName = null;
                              });
                              unawaited(() async {
                                final prefs =
                                    await SharedPreferences.getInstance();
                                await prefs.remove('weather_place_name');
                                await _load();
                              }());
                            },
                          ),
                          children: [
                            TileLayer(
                              urlTemplate:
                                  mapTileProviderById(_providerId).urlTemplate,
                              userAgentPackageName: 'com.sisumate.app',
                              tileProvider: CachingTileProvider(
                                providerId: _providerId,
                                cacheService: _tileCacheService,
                              ),
                            ),
                            if (_showSeamarks)
                              TileLayer(
                                urlTemplate: mapTileProviderById('openseamap')
                                    .urlTemplate,
                                userAgentPackageName: 'com.sisumate.app',
                                tileProvider: CachingTileProvider(
                                  providerId: 'openseamap',
                                  cacheService: _tileCacheService,
                                ),
                              ),
                            MarkerLayer(
                              markers: [
                                Marker(
                                  point: LatLng(
                                    double.tryParse(_latCtrl.text) ??
                                        _mapSeedLat,
                                    double.tryParse(_lonCtrl.text) ??
                                        _mapSeedLon,
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
                      // #239: shown clearly, distinct from routine forecast
                      // data — no banner at all when there's nothing active
                      // (silence, not a false "all clear" claim).
                      if (_hazardAlerts.isNotEmpty) ...[
                        _hazardBanner(isDark),
                        const SizedBox(height: 12),
                      ],
                      _currentCard(b, isDark),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _sectionTitle('Next 12 hours', isDark),
                          TextButton.icon(
                            onPressed: _comparingModels ? null : _compareModels,
                            icon: _comparingModels
                                ? const SizedBox(
                                    width: 14,
                                    height: 14,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : const Icon(Icons.compare_arrows, size: 18),
                            label: const Text('Compare models'),
                          ),
                        ],
                      ),
                      ...b.hourly.take(12).map((h) => _hourRow(h, isDark)),
                      const SizedBox(height: 12),
                      _sectionTitle('Daily', isDark),
                      ...b.daily.map((d) => _dayRow(d, isDark)),
                      if (b.marine.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        _sectionTitle('Waves (next hours)', isDark),
                        ...b.marine.take(8).map((m) => _marineRow(m, isDark)),
                      ],
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _sectionTitle('Tide & current (US/territories)', isDark),
                          TextButton.icon(
                            onPressed: _loadingTide ? null : _loadTideAndCurrent,
                            icon: _loadingTide
                                ? const SizedBox(
                                    width: 14,
                                    height: 14,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : const Icon(Icons.waves, size: 18),
                            label: const Text('Load'),
                          ),
                        ],
                      ),
                      ..._tideAndCurrentSection(isDark),
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
                    onChanged: (_) => _invalidatePlaceNameForCoordEdit(),
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
                    onChanged: (_) => _invalidatePlaceNameForCoordEdit(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Wrap (not Row+Spacer) — a Row can overflow horizontally on
            // narrow screens when all three controls' natural widths don't
            // fit; Wrap reflows to a second line instead (#173).
            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
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
                IconButton(
                  tooltip: 'Save place',
                  onPressed: _loading ? null : _saveFavorite,
                  icon: const Icon(Icons.bookmark_add_outlined),
                ),
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

  /// #239: active marine hazard alerts — a visually distinct warning card,
  /// never blended with the routine forecast display below it.
  Widget _hazardBanner(bool isDark) {
    return Material(
      color: Colors.red.withValues(alpha: isDark ? 0.25 : 0.1),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.warning_amber, color: Colors.red),
                const SizedBox(width: 8),
                Text(
                  'Active marine advisories',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: SisuColors.getTextPrimaryColor(isDark),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            for (final a in _hazardAlerts)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  '${a.event} — ${a.areaDesc}',
                  style: TextStyle(color: SisuColors.getTextPrimaryColor(isDark)),
                ),
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

  /// #229: matches by hour (not exact timestamp) since the ensemble and
  /// main forecast are two separate requests with their own time grids.
  EnsembleConfidence? _ensembleConfidenceForHour(DateTime t) {
    for (final e in _ensembleBundle?.hourly ?? const <EnsembleHourly>[]) {
      if (e.time.year == t.year &&
          e.time.month == t.month &&
          e.time.day == t.day &&
          e.time.hour == t.hour) {
        return e.confidence;
      }
    }
    return null;
  }

  String _confidenceLabel(EnsembleConfidence c) => switch (c) {
        EnsembleConfidence.high => 'models agree',
        EnsembleConfidence.medium => 'some model spread',
        EnsembleConfidence.low => 'models disagree',
      };

  Widget _hourRow(HourlyWeather h, bool isDark) {
    final prefs = ref.watch(unitPrefsProvider);
    final units = prefs.volumeSystem;
    final t =
        '${h.time.hour.toString().padLeft(2, '0')}:${h.time.minute.toString().padLeft(2, '0')}';
    final wind = h.windMs == null
        ? '-'
        : UnitConverter.formatSpeedFromMs(h.windMs!, prefs.windSpeed);
    final gust = h.windGustMs == null
        ? ''
        : ' (gusting ${UnitConverter.formatSpeedFromMs(h.windGustMs!, prefs.windSpeed)})';
    final temp = h.tempC == null
        ? '-'
        : UnitConverter.formatTempC(h.tempC!, units, temp: prefs.temperature);
    final confidence = _ensembleConfidenceForHour(h.time);
    final confidenceText =
        confidence == null ? '' : ' · ${_confidenceLabel(confidence)}';
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      title: Text(t,
          style: TextStyle(color: SisuColors.getTextPrimaryColor(isDark))),
      subtitle: Text(
        'Wind $wind$gust$confidenceText · rain ${h.precipProb?.round() ?? '-'}%',
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

  /// #234: tide/current rows, or a clear "not loaded yet" / "no nearby
  /// station" message — never silently blank with no explanation.
  List<Widget> _tideAndCurrentSection(bool isDark) {
    if (!_tideLoadAttempted) {
      return [
        Text('Tap Load for the nearest NOAA tide/current station '
            '(US/territories coverage only).',
            style: TextStyle(color: SisuColors.getTextSecondaryColor(isDark))),
      ];
    }
    final widgets = <Widget>[];
    if (_tideStation == null) {
      widgets.add(Text('No tide station within range of this location.',
          style: TextStyle(color: SisuColors.getTextSecondaryColor(isDark))));
    } else {
      widgets.add(Text(_tideStation!.name,
          style: TextStyle(
              fontWeight: FontWeight.w600,
              color: SisuColors.getTextPrimaryColor(isDark))));
      widgets.addAll(
          _tidePredictions.take(6).map((p) => _tideRow(p, isDark)));
    }
    widgets.add(const SizedBox(height: 8));
    if (_currentStation == null) {
      widgets.add(Text('No current station within range of this location.',
          style: TextStyle(color: SisuColors.getTextSecondaryColor(isDark))));
    } else {
      widgets.add(Text(_currentStation!.name,
          style: TextStyle(
              fontWeight: FontWeight.w600,
              color: SisuColors.getTextPrimaryColor(isDark))));
      widgets.addAll(
          _currentPredictions.take(6).map((p) => _currentRow(p, isDark)));
    }
    return widgets;
  }

  Widget _tideRow(TidePrediction p, bool isDark) {
    final t =
        '${p.time.hour.toString().padLeft(2, '0')}:${p.time.minute.toString().padLeft(2, '0')}';
    final label = p.type == 'H' ? 'High' : 'Low';
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      title: Text(t,
          style: TextStyle(color: SisuColors.getTextPrimaryColor(isDark))),
      subtitle: Text('$label tide · ${p.heightFt.toStringAsFixed(1)} ft',
          style: TextStyle(color: SisuColors.getTextSecondaryColor(isDark))),
    );
  }

  Widget _currentRow(CurrentPrediction p, bool isDark) {
    final t =
        '${p.time.hour.toString().padLeft(2, '0')}:${p.time.minute.toString().padLeft(2, '0')}';
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      title: Text(t,
          style: TextStyle(color: SisuColors.getTextPrimaryColor(isDark))),
      subtitle: Text(
        '${p.type[0].toUpperCase()}${p.type.substring(1)}'
        '${p.velocityKt == 0 ? '' : ' · ${p.velocityKt.abs().toStringAsFixed(1)} kt'}',
        style: TextStyle(color: SisuColors.getTextSecondaryColor(isDark)),
      ),
    );
  }
}

/// #233: side-by-side wind speed per model, clearly labeled so a user
/// reading "18kt / 24kt" knows why the numbers differ.
class _ModelComparisonDialog extends StatelessWidget {
  final MultiModelBundle bundle;
  final SpeedUnitPref speedUnit;
  const _ModelComparisonDialog({required this.bundle, required this.speedUnit});

  static const _modelLabels = {
    'gfs_seamless': 'GFS',
    'ecmwf_ifs025': 'ECMWF',
    'icon_seamless': 'ICON',
  };

  String _labelFor(String modelId) => _modelLabels[modelId] ?? modelId;

  @override
  Widget build(BuildContext context) {
    final rows = bundle.hourly.take(12).toList();
    return AlertDialog(
      title: const Text('Wind: model comparison'),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            columns: [
              const DataColumn(label: Text('Time')),
              ...bundle.models.map((m) => DataColumn(label: Text(_labelFor(m)))),
            ],
            rows: rows
                .map((h) => DataRow(cells: [
                      DataCell(Text(
                          '${h.time.hour.toString().padLeft(2, '0')}:${h.time.minute.toString().padLeft(2, '0')}')),
                      ...bundle.models.map((m) {
                        final ms = h.windSpeedMsByModel[m];
                        return DataCell(Text(ms == null
                            ? '-'
                            : UnitConverter.formatSpeedFromMs(ms, speedUnit)));
                      }),
                    ]))
                .toList(),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }
}
