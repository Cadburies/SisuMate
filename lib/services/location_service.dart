import 'package:geolocator/geolocator.dart';

/// Why a [LocationResult] carries no [Position] (#213 — extracted from
/// `weather_screen.dart`'s original inline GPS logic so Captain's Log can
/// reuse it without duplicating permission handling).
enum LocationFailureReason { serviceDisabled, permissionDenied, error }

class LocationResult {
  final Position? position;
  final LocationFailureReason? failureReason;
  final Object? error;

  const LocationResult.success(this.position)
      : failureReason = null,
        error = null;

  const LocationResult.failure(LocationFailureReason reason, [this.error])
      : position = null,
        failureReason = reason;

  bool get isSuccess => position != null;
}

/// Thin wrapper around [Geolocator] — permission check/request, then a
/// single position fix. No caching or continuous tracking.
class LocationService {
  const LocationService();

  Future<LocationResult> getCurrentPosition({
    LocationAccuracy accuracy = LocationAccuracy.medium,
    Duration timeLimit = const Duration(seconds: 12),
  }) async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return const LocationResult.failure(
            LocationFailureReason.serviceDisabled);
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return const LocationResult.failure(
            LocationFailureReason.permissionDenied);
      }

      final pos = await Geolocator.getCurrentPosition(
        locationSettings: LocationSettings(
          accuracy: accuracy,
          timeLimit: timeLimit,
        ),
      );
      return LocationResult.success(pos);
    } catch (e) {
      return LocationResult.failure(LocationFailureReason.error, e);
    }
  }
}
