import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sisu_mate/core/platform_capabilities.dart';
import 'package:sisu_mate/services/imu_sea_state_service.dart';

/// #343 — desktop must not call plugins that have no implementation.
void main() {
  test('ads and motion sensors are phone-only', () {
    if (Platform.isMacOS || Platform.isWindows || Platform.isLinux) {
      expect(DeviceCapabilities.ads, isFalse);
      expect(DeviceCapabilities.motionSensors, isFalse);
      expect(DeviceCapabilities.inAppPurchaseUi, isFalse);
    }
    if (Platform.isAndroid || Platform.isIOS) {
      expect(DeviceCapabilities.ads, isTrue);
      expect(DeviceCapabilities.motionSensors, isTrue);
    }
  });

  test('IMU start is a no-op on platforms without sensors_plus', () {
    if (DeviceCapabilities.motionSensors) return;
    final imu = ImuSeaStateService();
    imu.start();
    expect(imu.isListening, isFalse);
    expect(imu.lastError, isNotNull);
    imu.stop();
  });

  test('iOS project opts out of Designed-for-iPhone-on-Mac (#344)', () {
    final pbx = File('ios/Runner.xcodeproj/project.pbxproj').readAsStringSync();
    expect(pbx, contains('SUPPORTS_MAC_DESIGNED_FOR_IPHONE_IPAD = NO'));
    expect(pbx, contains('SUPPORTS_MACCATALYST = NO'));
  });

  test('native macOS deployment target is 13.0 (#343)', () {
    final pod = File('macos/Podfile').readAsStringSync();
    expect(pod, contains("platform :osx, '13.0'"));
    final pbx = File('macos/Runner.xcodeproj/project.pbxproj').readAsStringSync();
    expect(pbx, contains('MACOSX_DEPLOYMENT_TARGET = 13.0'));
    expect(pbx, isNot(contains('MACOSX_DEPLOYMENT_TARGET = 10.15')));
  });
}
