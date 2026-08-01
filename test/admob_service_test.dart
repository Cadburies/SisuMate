import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sisu_mate/services/admob_platform.dart';
import 'package:sisu_mate/services/admob_service.dart';

void main() {
  setUp(() {
    AdMobService.resetInitializedForTests();
  });

  group('AdMobService interstitial daily limit', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('allows showing an ad when nothing has been recorded yet', () async {
      final service = AdMobService(platform: FakeAdMobPlatform());
      expect(await service.canShowInterstitialAd(), isTrue);
    });

    test('allows up to maxInterstitialAdsPerDay ads, then blocks', () async {
      final service = AdMobService(platform: FakeAdMobPlatform());
      for (var i = 0; i < AdMobService.maxInterstitialAdsPerDay; i++) {
        expect(await service.canShowInterstitialAd(), isTrue);
        await service.recordInterstitialAdShown();
      }
      expect(await service.canShowInterstitialAd(), isFalse);
    });

    test('resets the count on a new day', () async {
      final service = AdMobService(platform: FakeAdMobPlatform());
      final prefs = await SharedPreferences.getInstance();
      // Simulate the limit already hit yesterday.
      await prefs.setString('interstitial_ad_date', '2020-01-01');
      await prefs.setInt(
          'interstitial_ad_count', AdMobService.maxInterstitialAdsPerDay);

      expect(await service.canShowInterstitialAd(), isTrue);
    });
  });

  group('AdMobService init / load / show (TEST4 fake platform)', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('init marks initialized on a supported platform', () async {
      final platform = FakeAdMobPlatform();
      final service = AdMobService(platform: platform);

      await service.init();

      expect(AdMobService.isInitialized, isTrue);
      expect(platform.initializeCalls, 1);
    });

    test('init skips when platform is unsupported', () async {
      final platform = FakeAdMobPlatform(isSupported: false);
      final service = AdMobService(platform: platform);

      await service.init();

      expect(AdMobService.isInitialized, isFalse);
      expect(platform.initializeCalls, 0);
    });

    test('init failure leaves the service uninitialized', () async {
      final platform = FakeAdMobPlatform(failInitialize: true);
      final service = AdMobService(platform: platform);

      await service.init();

      expect(AdMobService.isInitialized, isFalse);
    });

    test('createInterstitialAd loads a handle after init', () async {
      final platform = FakeAdMobPlatform();
      final service = AdMobService(platform: platform);
      await service.init();

      service.createInterstitialAd();

      expect(service.hasInterstitialReady, isTrue);
      expect(platform.loadCalls, 1);
    });

    test('createInterstitialAd is a no-op before init', () {
      final platform = FakeAdMobPlatform();
      final service = AdMobService(platform: platform);

      service.createInterstitialAd();

      expect(service.hasInterstitialReady, isFalse);
      expect(platform.loadCalls, 0);
    });

    test('retries load failures up to maxFailedLoadAttempts', () async {
      final platform = FakeAdMobPlatform(failLoadsUntil: 2);
      final service = AdMobService(platform: platform);
      await service.init();

      service.createInterstitialAd();

      // 2 failures + 1 success = 3 load calls; handle ready.
      expect(platform.loadCalls, 3);
      expect(service.hasInterstitialReady, isTrue);
      expect(service.interstitialLoadAttempts, 0);
    });

    test('stops retrying after maxFailedLoadAttempts failures', () async {
      final platform = FakeAdMobPlatform(
        failLoadsUntil: AdMobService.maxFailedLoadAttempts + 5,
      );
      final service = AdMobService(platform: platform);
      await service.init();

      service.createInterstitialAd();

      expect(platform.loadCalls, AdMobService.maxFailedLoadAttempts);
      expect(service.hasInterstitialReady, isFalse);
      expect(
        service.interstitialLoadAttempts,
        AdMobService.maxFailedLoadAttempts,
      );
    });

    test('showInterstitialAdIfAllowed records the daily count on show',
        () async {
      final platform = FakeAdMobPlatform();
      final service = AdMobService(platform: platform);
      await service.init();
      service.createInterstitialAd();

      await service.showInterstitialAdIfAllowed();

      expect(platform.showCalls, 1);
      final prefs = await SharedPreferences.getInstance();
      // onShowed records exactly once via the fake platform.
      expect(prefs.getInt('interstitial_ad_count'), 1);
      // Still under the daily cap.
      expect(await service.canShowInterstitialAd(), isTrue);
    });

    test('showInterstitialAdIfAllowed respects the daily cap', () async {
      final platform = FakeAdMobPlatform();
      final service = AdMobService(platform: platform);
      await service.init();
      service.createInterstitialAd();

      for (var i = 0; i < AdMobService.maxInterstitialAdsPerDay; i++) {
        await service.recordInterstitialAdShown();
      }

      await service.showInterstitialAdIfAllowed();
      expect(platform.showCalls, 0);
      expect(service.hasInterstitialReady, isTrue);
    });

    test('showInterstitialAdIfAllowed no-ops without a loaded ad', () async {
      final platform = FakeAdMobPlatform();
      final service = AdMobService(platform: platform);
      await service.init();

      await service.showInterstitialAdIfAllowed();
      expect(platform.showCalls, 0);
    });

    test('createBannerAd / createNativeAd return null when not initialized',
        () {
      final service = AdMobService(platform: FakeAdMobPlatform());
      expect(service.createBannerAd(), isNull);
      expect(service.createNativeAd(), isNull);
    });

    test('createBannerAd / createNativeAd return null when unsupported',
        () async {
      final platform = FakeAdMobPlatform(isSupported: false);
      final service = AdMobService(platform: platform);
      // Force the static flag so we isolate the isSupported check.
      AdMobService.resetInitializedForTests();
      expect(service.createBannerAd(), isNull);
      expect(service.createNativeAd(), isNull);
    });
  });

  group('AdMobService singleton (#123)', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    tearDown(() {
      AdMobService.instance.resetInterstitialStateForTests();
      AdMobService.debugSetPlatformForTests(const LiveAdMobPlatform());
      AdMobService.resetInitializedForTests();
    });

    test('no-arg construction returns the shared instance', () {
      expect(identical(AdMobService(), AdMobService()), isTrue);
      expect(identical(AdMobService(), AdMobService.instance), isTrue);
    });

    test('platform construction still returns isolated instances', () {
      final a = AdMobService(platform: FakeAdMobPlatform());
      final b = AdMobService(platform: FakeAdMobPlatform());
      expect(identical(a, b), isFalse);
      expect(identical(a, AdMobService.instance), isFalse);
    });

    test('interstitial state persists across independent constructions',
        () async {
      final platform = FakeAdMobPlatform();
      AdMobService.debugSetPlatformForTests(platform);
      final a = AdMobService();
      await a.init();

      a.createInterstitialAd();

      // A second, independent `AdMobService()` (what the gate call sites do)
      // must see the same loaded ad — the pre-#123 orphan bug.
      final b = AdMobService();
      expect(b.hasInterstitialReady, isTrue);
      expect(platform.loadCalls, 1);
    });

    test('createInterstitialAd is idempotent while an ad is ready', () async {
      final platform = FakeAdMobPlatform();
      AdMobService.debugSetPlatformForTests(platform);
      final a = AdMobService();
      await a.init();

      a.createInterstitialAd();
      a.createInterstitialAd();
      a.createInterstitialAd();

      expect(platform.loadCalls, 1);
    });

    test('awaitInterstitialReady returns once the ad is loaded', () async {
      final platform = FakeAdMobPlatform();
      AdMobService.debugSetPlatformForTests(platform);
      final a = AdMobService();
      await a.init();
      a.createInterstitialAd();

      await a.awaitInterstitialReady(timeout: const Duration(seconds: 1));

      expect(AdMobService().hasInterstitialReady, isTrue);
    });

    test('reset seam clears singleton interstitial state', () async {
      final platform = FakeAdMobPlatform();
      AdMobService.debugSetPlatformForTests(platform);
      final a = AdMobService();
      await a.init();
      a.createInterstitialAd();
      expect(a.hasInterstitialReady, isTrue);

      a.resetInterstitialStateForTests();

      expect(a.hasInterstitialReady, isFalse);
      expect(a.interstitialLoadAttempts, 0);
    });

    test('daily cap blocks the 4th show through the singleton', () async {
      final platform = FakeAdMobPlatform();
      AdMobService.debugSetPlatformForTests(platform);
      final a = AdMobService();
      await a.init();
      a.createInterstitialAd();

      // First three gate triggers show (fake platform auto-reloads on
      // dismiss via the service's onDismissed → createInterstitialAd).
      for (var i = 0; i < AdMobService.maxInterstitialAdsPerDay; i++) {
        await a.showInterstitialAdIfAllowed();
      }
      expect(platform.showCalls, AdMobService.maxInterstitialAdsPerDay);

      // 4th same-day trigger: cap blocks even though an ad is loaded.
      await a.showInterstitialAdIfAllowed();
      expect(platform.showCalls, AdMobService.maxInterstitialAdsPerDay);
    });
  });
}
