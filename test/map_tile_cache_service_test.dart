import 'dart:io';

import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sisu_mate/services/map_tile_cache_service.dart';

/// #240/#241: MapTileCacheService's disk cache is entirely separate from
/// flutter_map's own built-in tile cache (which can't support region-scoped
/// clearing — see the service's doc comment). Every test here uses an
/// explicit cache-folder override pointing at a real temp directory, so
/// none of this needs path_provider's getApplicationCacheDirectory (whose
/// Pigeon channel isn't mockable in this test environment — same gap noted
/// in #212's weather_map_recenter_test.dart).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  late MapTileCacheService service;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    tempDir = await Directory.systemTemp.createTemp('map_tile_cache_test');
    service = MapTileCacheService();
    await service.setCacheFolderOverride(tempDir.path);
  });

  tearDown(() async {
    if (await tempDir.exists()) await tempDir.delete(recursive: true);
  });

  group('cache folder override', () {
    test('cacheRootDir reflects the override', () async {
      final root = await service.cacheRootDir();
      expect(root.path, tempDir.path);
    });

    test('clearing the override falls back to null (default)', () async {
      await service.setCacheFolderOverride(null);
      expect(await service.cacheFolderOverride(), isNull);
    });
  });

  group('tileRangeForBounds', () {
    test('a tight bounding box at high zoom covers a small tile range', () {
      // Cape Town, roughly.
      final bounds = LatLngBounds(
        const LatLng(-33.93, 18.41),
        const LatLng(-33.92, 18.43),
      );
      final range = tileRangeForBounds(bounds, 14);
      expect(range.maxX, greaterThanOrEqualTo(range.minX));
      expect(range.maxY, greaterThanOrEqualTo(range.minY));
      // A ~0.01-0.02 degree box at zoom 14 should be a handful of tiles,
      // not the whole world.
      final count =
          (range.maxX - range.minX + 1) * (range.maxY - range.minY + 1);
      expect(count, lessThan(20));
    });

    test('a wider bounding box covers more tiles than a tight one at the '
        'same zoom', () {
      final tight = tileRangeForBounds(
        LatLngBounds(const LatLng(-33.93, 18.41), const LatLng(-33.92, 18.43)),
        10,
      );
      final wide = tileRangeForBounds(
        LatLngBounds(const LatLng(-34.5, 17.5), const LatLng(-33.0, 19.5)),
        10,
      );
      final tightCount =
          (tight.maxX - tight.minX + 1) * (tight.maxY - tight.minY + 1);
      final wideCount =
          (wide.maxX - wide.minX + 1) * (wide.maxY - wide.minY + 1);
      expect(wideCount, greaterThan(tightCount));
    });
  });

  group('tileFile', () {
    test('builds a deterministic path under <root>/<providerId>/<z>/<x>/<y>.png',
        () async {
      final file = await service.tileFile('esri_world_imagery', 8, 45, 100);
      expect(file.path, '${tempDir.path}/esri_world_imagery/8/45/100.png');
    });
  });

  group('clearRegion', () {
    Future<void> writeFakeTile(String providerId, int z, int x, int y) async {
      final file = await service.tileFile(providerId, z, x, y);
      await file.parent.create(recursive: true);
      await file.writeAsBytes([1, 2, 3]);
    }

    test('deletes only tiles within the given provider+region+zoom',
        () async {
      final bounds = LatLngBounds(
        const LatLng(-33.93, 18.41),
        const LatLng(-33.92, 18.43),
      );
      final range = tileRangeForBounds(bounds, 12);

      // Inside the region, correct provider — should be deleted.
      await writeFakeTile('osm', 12, range.minX, range.minY);
      // Same tile coords, DIFFERENT provider — must survive.
      await writeFakeTile('esri_world_imagery', 12, range.minX, range.minY);
      // Same provider, DIFFERENT zoom — must survive (out of scope).
      await writeFakeTile('osm', 8, range.minX, range.minY);
      // Same provider/zoom, way outside the region — must survive.
      await writeFakeTile('osm', 12, range.maxX + 1000, range.maxY + 1000);

      final deleted =
          await service.clearRegion(providerId: 'osm', bounds: bounds, zoom: 12);

      expect(deleted, greaterThanOrEqualTo(1));
      expect(
          await (await service.tileFile('osm', 12, range.minX, range.minY))
              .exists(),
          isFalse);
      expect(
          await (await service.tileFile(
                  'esri_world_imagery', 12, range.minX, range.minY))
              .exists(),
          isTrue,
          reason: 'a different provider at the same tile coords must survive');
      expect(await (await service.tileFile('osm', 8, range.minX, range.minY))
          .exists(), isTrue,
          reason: 'a different zoom must survive');
      expect(
          await (await service.tileFile(
                  'osm', 12, range.maxX + 1000, range.maxY + 1000))
              .exists(),
          isTrue,
          reason: 'a tile outside the region must survive');
    });

    test('returns 0 when nothing is cached for that region', () async {
      final bounds = LatLngBounds(
        const LatLng(-33.93, 18.41),
        const LatLng(-33.92, 18.43),
      );
      final deleted = await service.clearRegion(
          providerId: 'osm', bounds: bounds, zoom: 12);
      expect(deleted, 0);
    });
  });

  group('prefetchViewport', () {
    test('fetches and caches every tile in a small viewport, skipping '
        'ones already cached', () async {
      var requestCount = 0;
      final client = MockClient((request) async {
        requestCount++;
        return http.Response.bytes([1, 2, 3], 200);
      });
      final bounds = LatLngBounds(
        const LatLng(-33.93, 18.41),
        const LatLng(-33.92, 18.43),
      );
      const zoom = 14;

      final first = await service.prefetchViewport(
        providerId: 'osm',
        urlTemplate: 'https://tile.osm.example/{z}/{x}/{y}.png',
        bounds: bounds,
        zoom: zoom,
        client: client,
      );
      expect(first, greaterThan(0));
      final firstRequestCount = requestCount;

      // Re-running over the same viewport should fetch nothing new — every
      // tile is already on disk.
      final second = await service.prefetchViewport(
        providerId: 'osm',
        urlTemplate: 'https://tile.osm.example/{z}/{x}/{y}.png',
        bounds: bounds,
        zoom: zoom,
        client: client,
      );
      expect(second, 0);
      expect(requestCount, firstRequestCount,
          reason: 'already-cached tiles must not be re-fetched');
    });

    test('returns null without fetching anything when the viewport has '
        'too many tiles', () async {
      var requestCount = 0;
      final client = MockClient((request) async {
        requestCount++;
        return http.Response.bytes([1, 2, 3], 200);
      });
      // The whole world at a low zoom is a huge tile range.
      final bounds = LatLngBounds(
        const LatLng(-80, -170),
        const LatLng(80, 170),
      );

      final result = await service.prefetchViewport(
        providerId: 'osm',
        urlTemplate: 'https://tile.osm.example/{z}/{x}/{y}.png',
        bounds: bounds,
        zoom: 10,
        maxTiles: 200,
        client: client,
      );

      expect(result, isNull);
      expect(requestCount, 0,
          reason: 'an oversized viewport must not silently download '
              'thousands of tiles');
    });

    test('#241: fetches tiles in bounded-concurrency batches, not strictly '
        'one at a time — a dead connection must not make the wall-clock '
        'cost scale linearly with tile count', () async {
      var inFlight = 0;
      var maxInFlight = 0;
      final client = MockClient((request) async {
        inFlight++;
        if (inFlight > maxInFlight) maxInFlight = inFlight;
        await Future<void>.delayed(const Duration(milliseconds: 100));
        inFlight--;
        return http.Response.bytes([1, 2, 3], 200);
      });
      // Wide enough at this zoom to need more tiles than the default
      // concurrency of 6, so this actually exercises multiple batches.
      final bounds = LatLngBounds(
        const LatLng(-36.0, 15.0),
        const LatLng(-31.0, 22.0),
      );

      final stopwatch = Stopwatch()..start();
      final fetched = await service.prefetchViewport(
        providerId: 'osm',
        urlTemplate: 'https://tile.osm.example/{z}/{x}/{y}.png',
        bounds: bounds,
        zoom: 8,
        maxTiles: 500,
        client: client,
      );
      stopwatch.stop();

      expect(fetched, greaterThan(6),
          reason: 'this bbox/zoom must yield more tiles than the default '
              'concurrency to actually test batching');
      expect(maxInFlight, greaterThan(1),
          reason: 'tiles must be requested concurrently, not one at a time');
      // Sequential-at-100ms-each would take fetched*100ms; batched at
      // concurrency 6 should take roughly ceil(fetched/6)*100ms. Assert
      // well below the fully-sequential cost as the regression guard.
      expect(stopwatch.elapsedMilliseconds, lessThan(fetched! * 100),
          reason: 'must be materially faster than one-tile-at-a-time');
    });
  });
}
