import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Shared platform-channel stubs for widget / integration tests that pump
/// screens using [TitleTile] (connectivity) or path_provider-backed code.
void mockConnectivityChannel({bool online = true}) {
  const channel = MethodChannel('dev.fluttercommunity.plus/connectivity');
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(channel, (call) async {
    if (call.method == 'check') {
      return <String>[online ? 'wifi' : 'none'];
    }
    // onConnectivityChanged subscription handshake.
    return null;
  });

  // EventChannel used by Connectivity().onConnectivityChanged.
  const statusChannel =
      MethodChannel('dev.fluttercommunity.plus/connectivity_status');
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(statusChannel, (call) async {
    // listen/cancel for EventChannel — no events needed for smoke tests.
    return null;
  });
}

/// path_provider is hit by image/cache code paths; return a temp-like path.
void mockPathProviderChannel() {
  const channel = MethodChannel('plugins.flutter.io/path_provider');
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(channel, (call) async {
    switch (call.method) {
      case 'getApplicationDocumentsPath':
      case 'getApplicationSupportPath':
      case 'getTemporaryPath':
      case 'getLibraryPath':
        return '/tmp/sisu_mate_test';
      default:
        return null;
    }
  });
}

/// SharedPreferences already has [SharedPreferences.setMockInitialValues];
/// this covers the plugin channel when code goes through the method channel
/// before the mock is installed.
void mockSharedPreferencesChannel() {
  const channel = MethodChannel('plugins.flutter.io/shared_preferences');
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(channel, (call) async {
    if (call.method == 'getAll') return <String, Object>{};
    return null;
  });
}
