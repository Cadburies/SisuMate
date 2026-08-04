import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// #240/#241: multi-provider basemap + tile-download/cache framework wired
/// into weather_screen.dart. Source-scan rather than a full WeatherScreen
/// widget mount — same reason as #212's weather_map_recenter_test.dart:
/// flutter_map's default tile provider needs path_provider's Pigeon-based
/// getApplicationCacheDirectory channel, not mockable in this environment.
/// Behavioral coverage for the actual caching/prefetch/clear mechanisms
/// lives in map_tile_cache_service_test.dart and
/// caching_tile_provider_test.dart, which don't need a live map render.
void main() {
  test('weather_screen.dart wires the basemap picker, seamarks overlay, '
      'and tile download/clear actions into its drawer and map layers', () {
    final source = File(
      '${Directory.current.path}/lib/ui/weather/weather_screen.dart',
    ).readAsStringSync();

    expect(source.contains('_showProviderPicker(context)'), isTrue,
        reason: 'the Basemap drawer tile must open the provider picker');
    expect(source.contains('onChanged: _setSeamarksOverlay'), isTrue,
        reason: 'the seamarks overlay toggle must be wired up');
    expect(source.contains('onTap: _prefetching ? null : _downloadTilesForView'),
        isTrue,
        reason: '"Download tiles for this view" must call the prefetch action');
    expect(source.contains('onTap: _clearTilesForView'), isTrue,
        reason: '"Clear cached tiles for this view" must call the clear action');
    expect(source.contains('onTap: _pickCacheFolder'), isTrue,
        reason: 'the cache-folder setting must open the folder picker');

    expect(source.contains('tileProvider: CachingTileProvider('), isTrue,
        reason:
            'the base TileLayer must render through the disk-caching provider, '
            'not flutter_map\'s own unmanageable built-in cache');
    expect(source.contains('providerId: _providerId,'), isTrue,
        reason: 'the base tile layer must use the currently selected provider');
    expect(source.contains("providerId: 'openseamap',"), isTrue,
        reason: 'the overlay tile layer must be the openseamap provider');
    expect(source.contains('if (_showSeamarks)'), isTrue,
        reason: 'the OpenSeaMap overlay must be conditional, not always-on');
  });

  test('#233: "Compare models" is user-triggered and never folded into '
      'the automatic weather load', () {
    final source = File(
      '${Directory.current.path}/lib/ui/weather/weather_screen.dart',
    ).readAsStringSync();

    expect(source.contains('onPressed: _comparingModels ? null : _compareModels'),
        isTrue,
        reason: 'the "Compare models" button must call the on-demand action');
    expect(source.contains('_ModelComparisonDialog('), isTrue,
        reason: 'must open the comparison dialog on success');

    // _load() (the automatic-on-refresh path) must not call fetchMultiModel
    // — only _compareModels may. Crude but effective: fetchMultiModel()
    // should appear exactly once in the whole file (inside _compareModels).
    final occurrences =
        RegExp(r'\.fetchMultiModel\(').allMatches(source).length;
    expect(occurrences, 1,
        reason: 'fetchMultiModel must only be called from the explicit '
            'compare action, never from _load()/_restoreAndLoad');
  });

  test('#234: tide/current is user-triggered (station list fetch is '
      'expensive) and degrades gracefully with no coverage', () {
    final source = File(
      '${Directory.current.path}/lib/ui/weather/weather_screen.dart',
    ).readAsStringSync();

    expect(source.contains('onPressed: _loadingTide ? null : _loadTideAndCurrent'),
        isTrue,
        reason: 'the "Load" tide/current button must call the on-demand action');
    expect(source.contains('No tide station within range'), isTrue,
        reason: 'no nearby station must show a clear message, not silence '
            'or a crash');
    expect(source.contains('No current station within range'), isTrue);

    final tideStationCalls =
        RegExp(r'\.fetchTideStations\(').allMatches(source).length;
    expect(tideStationCalls, 1,
        reason: 'fetchTideStations must only be called from the explicit '
            'load action, never from _load()/_restoreAndLoad');
  });

  test('#239: marine hazard alerts are fetched alongside the automatic '
      'weather load (a single lightweight query, unlike #234\'s multi-MB '
      'station list) and shown as a distinct banner only when active', () {
    final source = File(
      '${Directory.current.path}/lib/ui/weather/weather_screen.dart',
    ).readAsStringSync();

    expect(source.contains('_marineHazardService.fetchActiveAlerts('), isTrue,
        reason: 'must be part of the same Future.wait as the main fetch');
    expect(source.contains('if (_hazardAlerts.isNotEmpty)'), isTrue,
        reason: 'no active alerts must mean no banner at all — silence, '
            'never a false "all clear" claim');
  });
}
