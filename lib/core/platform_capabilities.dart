import 'dart:io';

import 'package:flutter/foundation.dart';

/// Which native plugins actually exist on this OS. Call sites must not
/// invoke a plugin that is `false` here — that is a MissingPluginException
/// (or a hard crash) on desktop.
///
/// Native **Flutter macOS** (`Platform.isMacOS`) is not the same as an
/// **iOS IPA running on Apple Silicon Mac** (`Platform.isIOS`). That second
/// path is opted out in the iOS Xcode project, not gated here.
class DeviceCapabilities {
  DeviceCapabilities._();

  static bool get ads =>
      !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  /// RevenueCat `purchases_flutter` (offerings / restore). Not the UI package.
  static bool get inAppPurchases =>
      !kIsWeb && (Platform.isAndroid || Platform.isIOS || Platform.isMacOS);

  /// `purchases_ui_flutter` native paywall sheet — mobile only.
  static bool get inAppPurchaseUi =>
      !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  static bool get cameraScanner =>
      !kIsWeb && (Platform.isAndroid || Platform.isIOS || Platform.isMacOS);

  /// `sensors_plus` accelerometer / IMU — no macOS or Windows plugin.
  static bool get motionSensors =>
      !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  static bool get location =>
      !kIsWeb &&
      (Platform.isAndroid ||
          Platform.isIOS ||
          Platform.isMacOS ||
          Platform.isWindows);

  static bool get lanMulticast =>
      !kIsWeb &&
      (Platform.isAndroid ||
          Platform.isIOS ||
          Platform.isMacOS ||
          Platform.isWindows ||
          Platform.isLinux);
}
