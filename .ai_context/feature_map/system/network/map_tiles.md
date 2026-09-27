title: Map tiles and offline caching
desc: Chart and satellite map tiles for Weather, the passage planner and the anchor chart, cached for offline use.
layer: network
keywords: map, tiles, chart, satellite, cache, offline
kind: service
looks: -
reach: any map view
needs: -
action: Downloads tiles when online and serves cached tiles offline.
expect: Previously viewed areas still show offline.
uses: -
script: test/map_tile_cache_service_test.dart
source: lib/services/map_tile_cache_service.dart (MapTileCacheService); lib/services/map_tile_providers.dart
