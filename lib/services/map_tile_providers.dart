/// #240: catalog of selectable map basemaps/overlays. Research findings
/// (2026-08-02, not load-tested at scale — see the filed issue):
/// - OSM: free, standard attribution required.
/// - Esri World Imagery / Ocean Basemap: free for light/eval use; Esri's
///   terms are NOT confirmed safe for sustained production app-scale
///   traffic (commercial apps are typically expected to hold an ArcGIS
///   account/API key at volume) — [MapTileProviderConfig.usageCaveat]
///   surfaces this in the UI rather than silently assuming it's fine.
/// - OpenSeaMap: nautical seamarks/buoys — a transparent overlay, not a
///   standalone basemap (isOverlay: true); free community server, no
///   formal rate-limit SLA.
class MapTileProviderConfig {
  final String id;
  final String label;
  final String urlTemplate;
  final bool isOverlay;
  final String attribution;
  final String? usageCaveat;

  const MapTileProviderConfig({
    required this.id,
    required this.label,
    required this.urlTemplate,
    required this.attribution,
    this.isOverlay = false,
    this.usageCaveat,
  });
}

/// #264 — SharedPreferences key for the user's basemap choice. Weather and
/// Anchor Alarm both read/write this so satellite/OSM/nautical stay in sync.
const kMapTileProviderIdPrefKey = 'map_tile_provider_id';

const mapTileBaseProviders = <MapTileProviderConfig>[
  MapTileProviderConfig(
    id: 'osm',
    label: 'OpenStreetMap',
    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
    attribution: '© OpenStreetMap contributors',
  ),
  MapTileProviderConfig(
    id: 'esri_world_imagery',
    label: 'Satellite (Esri World Imagery)',
    urlTemplate:
        'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}',
    attribution: 'Esri, Maxar, Earthstar Geographics',
    usageCaveat: 'Free for light use; Esri\'s terms are not confirmed safe '
        'for sustained production-scale traffic.',
  ),
  MapTileProviderConfig(
    id: 'esri_ocean',
    label: 'Nautical / Bathymetry (Esri Ocean Basemap)',
    urlTemplate:
        'https://server.arcgisonline.com/ArcGIS/rest/services/Ocean/World_Ocean_Base/MapServer/tile/{z}/{y}/{x}',
    attribution: 'Esri, GEBCO, NOAA, National Geographic, DeLorme, HERE, Geonames.org',
    usageCaveat: 'Free for light use; Esri\'s terms are not confirmed safe '
        'for sustained production-scale traffic.',
  ),
];

const mapTileOverlayProviders = <MapTileProviderConfig>[
  MapTileProviderConfig(
    id: 'openseamap',
    label: 'Nautical marks (OpenSeaMap)',
    urlTemplate: 'https://tiles.openseamap.org/seamark/{z}/{x}/{y}.png',
    attribution: '© OpenSeaMap contributors',
    isOverlay: true,
  ),
];

MapTileProviderConfig mapTileProviderById(String id) =>
    [...mapTileBaseProviders, ...mapTileOverlayProviders]
        .firstWhere((p) => p.id == id, orElse: () => mapTileBaseProviders.first);
