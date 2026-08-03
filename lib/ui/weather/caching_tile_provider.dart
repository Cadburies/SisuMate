import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart' as http;

import '../../services/map_tile_cache_service.dart';

/// #240: a [TileProvider] backed by [MapTileCacheService]'s deterministic
/// on-disk cache — checks the cache file first (direct z/x/y from
/// [TileCoordinates], no URL parsing needed), falls back to network and
/// writes through on a miss. Deliberately not flutter_map's own
/// [NetworkTileProvider]/built-in cache — see MapTileCacheService's doc
/// comment for why that one can't support region-scoped clearing.
class CachingTileProvider extends TileProvider {
  final String providerId;
  final MapTileCacheService cacheService;
  final http.Client? httpClient;

  CachingTileProvider({
    required this.providerId,
    required this.cacheService,
    this.httpClient,
    super.headers,
  });

  @override
  ImageProvider getImage(TileCoordinates coordinates, TileLayer options) {
    final url = getTileUrl(coordinates, options);
    return _CachingTileImage(
      url: url,
      providerId: providerId,
      z: coordinates.z,
      x: coordinates.x,
      y: coordinates.y,
      cacheService: cacheService,
      httpClient: httpClient,
    );
  }
}

class _CachingTileImage extends ImageProvider<_CachingTileImage> {
  final String url;
  final String providerId;
  final int z, x, y;
  final MapTileCacheService cacheService;
  final http.Client? httpClient;

  const _CachingTileImage({
    required this.url,
    required this.providerId,
    required this.z,
    required this.x,
    required this.y,
    required this.cacheService,
    this.httpClient,
  });

  @override
  Future<_CachingTileImage> obtainKey(ImageConfiguration configuration) =>
      SynchronousFuture(this);

  @override
  ImageStreamCompleter loadImage(
    _CachingTileImage key,
    ImageDecoderCallback decode,
  ) {
    return MultiFrameImageStreamCompleter(
      codec: _load(decode),
      scale: 1.0,
      debugLabel: url,
      informationCollector: () => [
        DiagnosticsProperty<String>('Tile URL', url),
        DiagnosticsProperty<String>('Provider', providerId),
      ],
    );
  }

  Future<ui.Codec> _load(ImageDecoderCallback decode) async {
    final file = await cacheService.tileFile(providerId, z, x, y);
    Uint8List bytes;
    if (await file.exists()) {
      bytes = await file.readAsBytes();
    } else {
      final client = httpClient ?? http.Client();
      // See MapTileCacheService.prefetchViewport's comment — a dead
      // connection must not hang a live tile's load indefinitely.
      final response =
          await client.get(Uri.parse(url)).timeout(const Duration(seconds: 10));
      if (response.statusCode != 200) {
        throw HttpException('Tile fetch failed: ${response.statusCode}', uri: Uri.parse(url));
      }
      bytes = response.bodyBytes;
      unawaited(() async {
        try {
          await file.parent.create(recursive: true);
          await file.writeAsBytes(bytes);
        } catch (_) {
          // Caching is best-effort — a write failure shouldn't break the
          // tile that already loaded successfully.
        }
      }());
    }
    final buffer = await ui.ImmutableBuffer.fromUint8List(bytes);
    return decode(buffer);
  }

  @override
  bool operator ==(Object other) =>
      other is _CachingTileImage &&
      other.url == url &&
      other.providerId == providerId;

  @override
  int get hashCode => Object.hash(url, providerId);
}
