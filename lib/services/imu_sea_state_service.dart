import 'dart:async';

import 'package:sensors_plus/sensors_plus.dart';

import '../core/platform_capabilities.dart';
import 'error_log_service.dart';
import 'imu_heave_estimator.dart';

/// #280 — phone accelerometer → [ImuHeaveEstimator] while the app is active.
///
/// Foreground-oriented (same practical window as polar background collector).
/// Safe on platforms without sensors: start fails soft, estimate stays empty.
class ImuSeaStateService {
  ImuSeaStateService({
    this.samplingInterval = const Duration(milliseconds: 50),
    ImuHeaveEstimator? estimator,
  }) : _estimator = estimator ?? ImuHeaveEstimator();

  final Duration samplingInterval;
  final ImuHeaveEstimator _estimator;

  StreamSubscription<AccelerometerEvent>? _sub;
  bool _started = false;
  String? _lastError;

  ImuHeaveEstimator get estimator => _estimator;

  bool get isListening => _sub != null;

  String? get lastError => _lastError;

  /// Latest estimate (recomputed on demand from the rolling window).
  ImuSeaStateEstimate get currentEstimate => _estimator.evaluate();

  /// Begin accelerometer stream (idempotent).
  void start() {
    if (_started) return;
    if (!DeviceCapabilities.motionSensors) {
      _lastError = 'motion sensors unavailable on this platform';
      return;
    }
    _started = true;
    try {
      _sub = accelerometerEventStream(samplingPeriod: samplingInterval).listen(
        (e) {
          _estimator.addSample(
            ImuAccelSample(
              at: DateTime.now().toUtc(),
              ax: e.x,
              ay: e.y,
              az: e.z,
            ),
          );
        },
        onError: (Object e) {
          _lastError = e.toString();
          unawaited(ErrorLogService().logWarning(
            'IMU accelerometer stream error: $e',
            context: 'imu_sea_state_service: stream',
          ));
        },
        cancelOnError: false,
      );
    } catch (e) {
      _lastError = e.toString();
      _started = false;
      unawaited(ErrorLogService().logWarning(
        'IMU accelerometer unavailable: $e',
        context: 'imu_sea_state_service: start',
      ));
    }
  }

  void stop() {
    _sub?.cancel();
    _sub = null;
    _started = false;
  }

  /// Test / offline path: inject samples without the platform sensor.
  void addSampleForTest(ImuAccelSample sample) =>
      _estimator.addSample(sample);

  void reset() => _estimator.reset();
}
