import 'package:http/http.dart' as http;

import '../models/models.dart';
import 'boat_instrument_failover_service.dart';
import 'location_service.dart';
import 'predictwind_datahub_service.dart';

/// #303 — which path produced the active lat/lon.
enum BoatPositionSource {
  /// Multi-source instrument failover (DataHub / YDWG / HA).
  instruments,

  /// Device GPS via [LocationService] after instruments had no usable fix.
  phoneGps,
}

/// Unified boat position: instruments first, optional phone GPS fallback.
///
/// Depth/wind remain on [instruments] even when position falls back to the
/// phone — phone only supplies lat/lon.
class BoatPositionResult {
  final double? latitude;
  final double? longitude;
  final BoatPositionSource? positionSource;
  final BoatInstrumentSnapshot instruments;
  final LocationFailureReason? phoneFailure;

  const BoatPositionResult({
    required this.instruments,
    this.latitude,
    this.longitude,
    this.positionSource,
    this.phoneFailure,
  });

  bool get hasPosition => latitude != null && longitude != null;

  /// Instrument payload when present (depth/wind/SOG may exist without a fix).
  PredictWindBoatData? get boatData => instruments.boatData;

  String get positionSourceLabel => switch (positionSource) {
        BoatPositionSource.instruments =>
          instruments.activeSource?.label ?? 'Boat instruments',
        BoatPositionSource.phoneGps => 'Phone GPS',
        null => 'No position',
      };
}

/// #303 — best-available boat position for Weather, Anchor Alarm, etc.
class BoatPositionService {
  const BoatPositionService({
    this.locationService = const LocationService(),
    this.failover = const BoatInstrumentFailoverService(),
  });

  final LocationService locationService;
  final BoatInstrumentFailoverService failover;

  /// Prefer instruments with a GPS fix; otherwise phone GPS when
  /// [allowPhoneFallback] is true (requests permission only on that path).
  Future<BoatPositionResult> fetchBest({
    required UserSettings? settings,
    required PredictWindDatahubService hubService,
    http.Client? client,
    bool allowPhoneFallback = true,
  }) async {
    final instruments = await failover.fetch(
      settings: settings,
      hubService: hubService,
      client: client,
    );

    if (instruments.hasFix) {
      final data = instruments.boatData!;
      return BoatPositionResult(
        latitude: data.latitude,
        longitude: data.longitude,
        positionSource: BoatPositionSource.instruments,
        instruments: instruments,
      );
    }

    if (!allowPhoneFallback) {
      return BoatPositionResult(instruments: instruments);
    }

    final phone = await locationService.getCurrentPosition();
    if (phone.isSuccess) {
      final pos = phone.position!;
      return BoatPositionResult(
        latitude: pos.latitude,
        longitude: pos.longitude,
        positionSource: BoatPositionSource.phoneGps,
        instruments: instruments,
      );
    }

    return BoatPositionResult(
      instruments: instruments,
      phoneFailure: phone.failureReason,
    );
  }
}
