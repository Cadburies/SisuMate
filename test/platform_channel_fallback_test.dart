import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sisu_mate/services/admob_platform.dart';
import 'package:sisu_mate/services/admob_service.dart';
import 'package:sisu_mate/services/profile_heartbeat.dart';
import 'package:sisu_mate/services/revenuecat_service.dart';

import 'test_helpers/fake_auth_backend.dart';
import 'test_helpers/platform_mocks.dart';

/// TEST10: services that talk to platform channels must degrade safely when
/// plugins are missing (unit-test host) or return empty data — never throw
/// into the UI isolate.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    AdMobService.resetInitializedForTests();
    ProfileHeartbeat.resetDebugHooks();
    RevenueCatService.debugProOverrideForTests = null;
  });

  tearDown(() {
    ProfileHeartbeat.resetDebugHooks();
    RevenueCatService.debugProOverrideForTests = null;
  });

  test('ProfileHeartbeat.stamp completes when hooks throw (offline / no channel)',
      () async {
    ProfileHeartbeat.debugCurrentUser = () async => fakeOwnerUser();
    ProfileHeartbeat.debugProExpiresAt =
        () async => throw MissingPluginException('no revenuecat');
    ProfileHeartbeat.debugUpsertProfile =
        (_) async => throw MissingPluginException('no supabase');

    await expectLater(ProfileHeartbeat.stamp(), completes);
  });

  test('AdMobService.init completes on unsupported platform without throwing',
      () async {
    final service = AdMobService(
      platform: FakeAdMobPlatform(isSupported: false),
    );
    await expectLater(service.init(), completes);
    expect(AdMobService.isInitialized, isFalse);
  });

  test('AdMobService.init completes when the platform initialize fails',
      () async {
    final service = AdMobService(
      platform: FakeAdMobPlatform(failInitialize: true),
    );
    await expectLater(service.init(), completes);
    expect(AdMobService.isInitialized, isFalse);
  });

  test('SharedPreferences daily-limit path works under mock channel', () async {
    mockSharedPreferencesChannel();
    SharedPreferences.setMockInitialValues({});
    final service = AdMobService(platform: FakeAdMobPlatform());
    expect(await service.canShowInterstitialAd(), isTrue);
    await service.recordInterstitialAdShown();
    expect(await service.canShowInterstitialAd(), isTrue);
  });

  test('connectivity mock returns offline status without throwing', () async {
    mockConnectivityChannel(online: false);
    const channel = MethodChannel('dev.fluttercommunity.plus/connectivity');
    final reply = await TestDefaultBinaryMessengerBinding
        .instance.defaultBinaryMessenger
        .send(
      channel.name,
      channel.codec.encodeMethodCall(const MethodCall('check')),
    );
    expect(reply, isNotNull);
    final decoded = channel.codec.decodeEnvelope(reply!);
    expect(decoded, isA<List>());
    expect(decoded, contains('none'));
  });
}
