import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// #240/#241: disk cache for map tiles, entirely separate from flutter_map's
/// own built-in cache — that cache keys tiles by a URL hash with no public
/// API to enumerate/query by provider or region (confirmed by reading its
/// source), so "clear cached esri tiles for the current view" isn't
/// achievable through it. This cache instead writes tiles to a
/// deterministic `<root>/<providerId>/<z>/<x>/<y>.png` path, so region-
/// scoped clearing is a directory walk over known filenames — no index/
/// database needed for correctness.
class MapTileCacheService {
  static const _cacheFolderPrefKey = 'map_tile_cache_folder';

  /// The configured root cache directory — a user override (folder picker
  /// in Weather's drawer) if set, otherwise `<app cache dir>/map_tiles`.
  Future<Directory> cacheRootDir() async {
    final prefs = await SharedPreferences.getInstance();
    final override = prefs.getString(_cacheFolderPrefKey);
    if (override != null && override.isNotEmpty) {
      return Directory(override);
    }
    final base = await getApplicationCacheDirectory();
    return Directory('${base.path}/map_tiles');
  }

  Future<String?> cacheFolderOverride() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_cacheFolderPrefKey);
  }

  Future<void> setCacheFolderOverride(String? path) async {
    final prefs = await SharedPreferences.getInstance();
    if (path == null || path.isEmpty) {
      await prefs.remove(_cacheFolderPrefKey);
    } else {
      await prefs.setString(_cacheFolderPrefKey, path);
    }
  }

  Future<File> tileFile(String providerId, int z, int x, int y) async {
    final root = await cacheRootDir();
    return File('${root.path}/$providerId/$z/$x/$y.png');
  }

  /// Fetches+caches every tile for [providerId] covering [bounds] at
  /// [zoom], skipping ones already on disk. Returns the number newly
  /// fetched. Bounded by [maxTiles] — an oversized viewport (e.g. zoomed
  /// far out) returns `null` without fetching anything rather than
  /// silently downloading thousands of tiles; the caller decides how to
  /// tell the user to zoom in first.
  Future<int?> prefetchViewport({
    required String providerId,
    required String urlTemplate,
    required LatLngBounds bounds,
    required int zoom,
    int maxTiles = 200,
    int concurrency = 6,
    http.Client? client,
  }) async {
    final c = client ?? http.Client();
    final range = tileRangeForBounds(bounds, zoom);
    final tileCount =
        (range.maxX - range.minX + 1) * (range.maxY - range.minY + 1);
    if (tileCount > maxTiles) return null;

    final pending = <(int, int)>[];
    for (var x = range.minX; x <= range.maxX; x++) {
      for (var y = range.minY; y <= range.maxY; y++) {
        final file = await tileFile(providerId, zoom, x, y);
        if (!await file.exists()) pending.add((x, y));
      }
    }

    // Bounded-concurrency batches, not one-at-a-time: a dead connection
    // hits its 10s timeout on every tile it's given regardless of
    // concurrency, so fetching sequentially made the worst case scale
    // linearly with tile count — found live on an emulator with no network
    // route, a ~20-tile viewport took several minutes one tile at a time.
    var fetched = 0;
    for (var i = 0; i < pending.length; i += concurrency) {
      final batch = pending.skip(i).take(concurrency);
      final results = await Future.wait(batch.map((coord) async {
        final (x, y) = coord;
        final url = urlTemplate
            .replaceAll('{z}', '$zoom')
            .replaceAll('{x}', '$x')
            .replaceAll('{y}', '$y');
        try {
          final response =
              await c.get(Uri.parse(url)).timeout(const Duration(seconds: 10));
          if (response.statusCode != 200) return false;
          final file = await tileFile(providerId, zoom, x, y);
          await file.parent.create(recursive: true);
          await file.writeAsBytes(response.bodyBytes);
          return true;
        } catch (_) {
          // Best-effort — one bad tile shouldn't abort the whole viewport.
          return false;
        }
      }));
      fetched += results.where((ok) => ok).length;
    }
    return fetched;
  }

  /// Deletes cached tiles for [providerId] within [bounds] at [zoom].
  /// Returns the number of files deleted.
  Future<int> clearRegion({
    required String providerId,
    required LatLngBounds bounds,
    required int zoom,
  }) async {
    final root = await cacheRootDir();
    final range = tileRangeForBounds(bounds, zoom);
    var deleted = 0;
    for (var x = range.minX; x <= range.maxX; x++) {
      for (var y = range.minY; y <= range.maxY; y++) {
        final file = File('${root.path}/$providerId/$zoom/$x/$y.png');
        if (await file.exists()) {
          await file.delete();
          deleted++;
        }
      }
    }
    return deleted;
  }

  /// Deletes every cached tile for [providerId], at every zoom/region.
  Future<int> clearProvider(String providerId) async {
    final root = await cacheRootDir();
    final dir = Directory('${root.path}/$providerId');
    if (!await dir.exists()) return 0;
    var deleted = 0;
    await for (final entity in dir.list(recursive: true)) {
      if (entity is File) deleted++;
    }
    await dir.delete(recursive: true);
    return deleted;
  }
}

/// Inclusive tile x/y range covering [bounds] at [zoom] — standard
/// slippy-map tile math (Web Mercator).
class TileRange {
  final int minX, maxX, minY, maxY;
  const TileRange(this.minX, this.maxX, this.minY, this.maxY);
}

TileRange tileRangeForBounds(LatLngBounds bounds, int zoom) {
  final nw = _tileCoord(bounds.north, bounds.west, zoom);
  final se = _tileCoord(bounds.south, bounds.east, zoom);
  return TileRange(
    math.min(nw.$1, se.$1),
    math.max(nw.$1, se.$1),
    math.min(nw.$2, se.$2),
    math.max(nw.$2, se.$2),
  );
}

(int, int) _tileCoord(double lat, double lon, int zoom) {
  final n = math.pow(2, zoom).toDouble();
  final x = ((lon + 180) / 360 * n).floor();
  final latRad = lat * (math.pi / 180);
  final y = ((1 -
              (math.log(math.tan(latRad) + 1 / math.cos(latRad)) / math.pi)) /
          2 *
          n)
      .floor();
  return (x, y);
}
