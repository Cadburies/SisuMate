import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geolocator_platform_interface/geolocator_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:sisu_mate/services/location_service.dart';

/// #213: [LocationService] was extracted from `weather_screen.dart`'s
/// inline GPS permission/fix logic so Captain's Log could reuse it without
/// duplicating ~30 lines of permission handling. This exercises the three
/// outcomes the original inline code branched on, against a fake
/// [GeolocatorPlatform] rather than a real device.
class _FakeGeolocatorPlatform extends GeolocatorPlatform
    with MockPlatformInterfaceMixin {
  bool serviceEnabled = true;
  LocationPermission permission = LocationPermission.always;
  Position? position;
  Object? throwOnGetPosition;

  @override
  Future<bool> isLocationServiceEnabled() async => serviceEnabled;

  @override
  Future<LocationPermission> checkPermission() async => permission;

  @override
  Future<LocationPermission> requestPermission() async => permission;

  @override
  Future<Position> getCurrentPosition({LocationSettings? locationSettings}) async {
    if (throwOnGetPosition != null) throw throwOnGetPosition!;
    return position!;
  }
}

Position _position({
  double lat = 33.0,
  double lon = -117.0,
  double speed = 0.0,
  double speedAccuracy = 0.0,
  double heading = 0.0,
  double headingAccuracy = 0.0,
}) =>
    Position(
      latitude: lat,
      longitude: lon,
      timestamp: DateTime(2026, 1, 1),
      accuracy: 5.0,
      altitude: 0.0,
      altitudeAccuracy: 0.0,
      heading: heading,
      headingAccuracy: headingAccuracy,
      speed: speed,
      speedAccuracy: speedAccuracy,
    );

void main() {
  late _FakeGeolocatorPlatform fake;

  setUp(() {
    fake = _FakeGeolocatorPlatform();
    GeolocatorPlatform.instance = fake;
  });

  test('service disabled reports serviceDisabled, no position', () async {
    fake.serviceEnabled = false;

    final result = await const LocationService().getCurrentPosition();

    expect(result.isSuccess, isFalse);
    expect(result.failureReason, LocationFailureReason.serviceDisabled);
    expect(result.position, isNull);
  });

  test('denied permission reports permissionDenied, no position', () async {
    fake.permission = LocationPermission.denied;

    final result = await const LocationService().getCurrentPosition();

    expect(result.isSuccess, isFalse);
    expect(result.failureReason, LocationFailureReason.permissionDenied);
  });

  test('deniedForever permission reports permissionDenied', () async {
    fake.permission = LocationPermission.deniedForever;

    final result = await const LocationService().getCurrentPosition();

    expect(result.failureReason, LocationFailureReason.permissionDenied);
  });

  test('a thrown exception during the fix is captured as failureReason.error',
      () async {
    fake.throwOnGetPosition = Exception('timeout');

    final result = await const LocationService().getCurrentPosition();

    expect(result.isSuccess, isFalse);
    expect(result.failureReason, LocationFailureReason.error);
    expect(result.error, isNotNull);
  });

  test('a successful fix returns the position with no failure reason',
      () async {
    fake.position = _position(lat: 33.4484, lon: -112.0740, speed: 3.0,
        speedAccuracy: 1.0, heading: 90.0, headingAccuracy: 5.0);

    final result = await const LocationService().getCurrentPosition();

    expect(result.isSuccess, isTrue);
    expect(result.failureReason, isNull);
    expect(result.position!.latitude, 33.4484);
    expect(result.position!.longitude, -112.0740);
    expect(result.position!.speed, 3.0);
    expect(result.position!.heading, 90.0);
  });
}
