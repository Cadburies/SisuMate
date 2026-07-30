import 'dart:io';

import 'package:flutter/foundation.dart';

class AdHelper {
  static String get deviceId {
    if (Platform.isAndroid) {
      return kDebugMode
          ? 'ca-app-pub-3940256099942544~3347511713' // Debug mode - Test Ads
          : 'ca-app-pub-1941448979345601~1220135606'; // Release mode - Real-time
    } else if (Platform.isIOS) {
      return kDebugMode
          ? 'ca-app-pub-3940256099942544~1458002511' //  Debug mode - Test Ads
          : 'ca-app-pub-1941448979345601~3437747519'; // Release mode - Real-time
    } else {
      throw UnsupportedError('Unsupported platform');
    }
  }

  static String get bannerAdUnitId {
    if (Platform.isAndroid) {
      return kDebugMode
          ? 'ca-app-pub-3940256099942544/6300978111' // Debug mode - Test Ads
          : 'ca-app-pub-1941448979345601/3239987806'; // Release mode - Real-time
    } else if (Platform.isIOS) {
      return kDebugMode
          ? 'ca-app-pub-3940256099942544/2934735716' //  Debug mode - Test Ads
          : 'ca-app-pub-1941448979345601/2479889062'; // Release mode - Real-time
    } else {
      throw UnsupportedError('Unsupported platform');
    }
  }

  static String get interstitialAdUnitId {
    if (Platform.isAndroid) {
      return kDebugMode
          ? "ca-app-pub-3940256099942544/1033173712" // Debug mode - Test Ads
          : "ca-app-pub-1941448979345601/4385548518"; // Release mode - Real-time
    } else if (Platform.isIOS) {
      return kDebugMode
          ? "ca-app-pub-3940256099942544/4411468910" // Debug mode - Test Ads
          : "ca-app-pub-1941448979345601/7516593325"; // Release mode - Real-time
    } else {
      throw UnsupportedError("Unsupported platform");
    }
  }

  static String get nativeAdUnitId {
    if (Platform.isAndroid) {
      return kDebugMode
          ? "ca-app-pub-3940256099942544/5224354917" // Debug mode - Test Ads
          : "ca-app-pub-1941448979345601/7458434418"; // Release mode - Real-time
    } else if (Platform.isIOS) {
      return kDebugMode
          ? "ca-app-pub-3940256099942544/1712485313" // Debug mode - Test Ads
          : "ca-app-pub-1941448979345601/6753303850"; // Release mode - Real-time
    } else {
      throw UnsupportedError("Unsupported platform");
    }
  }
}
