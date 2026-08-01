import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../ads/ad_helper.dart';
import 'admob_platform.dart';

class AdMobService {
  /// Shared instance for production call sites (#123: interstitial state —
  /// the loaded ad and the load-attempt counter — must survive across
  /// independent `AdMobService()` constructions; previously every call site
  /// built a fresh instance and orphaned any in-flight load).
  static final AdMobService instance =
      AdMobService._(const LiveAdMobPlatform());

  /// No-[platform] call sites share [instance]; tests that pass a platform
  /// keep getting their own isolated instance (TEST4 seam, unchanged).
  factory AdMobService({AdMobPlatform? platform}) =>
      platform == null ? instance : AdMobService._(platform);

  AdMobService._(AdMobPlatform platform) : _platform = platform;

  AdMobPlatform _platform;

  /// Swaps the singleton's platform (tests only; restore in tearDown).
  @visibleForTesting
  static void debugSetPlatformForTests(AdMobPlatform platform) {
    instance._platform = platform;
  }

  static bool _isInitialized = false;
  static bool get isInitialized => _isInitialized;

  /// Resets static init flag (tests only).
  @visibleForTesting
  static void resetInitializedForTests() {
    _isInitialized = false;
  }

  Future<void> init() async {
    if (!_platform.isSupported) {
      if (kDebugMode) {
        print(
            'AdMob: Skipping initialization - platform not supported');
      }
      return;
    }

    try {
      await _platform.initialize();
      _isInitialized = true;
      if (kDebugMode) print('AdMob: Successfully initialized');
    } catch (e) {
      if (kDebugMode) print('AdMob: Failed to initialize - $e');
      if (kDebugMode) print('AdMob: App will continue without ads');
      _isInitialized = false;
    }
  }

  BannerAd? createBannerAd() {
    if (!_platform.isSupported) {
      if (kDebugMode) {
        print('AdMob: Cannot create banner ad - platform not supported');
      }
      return null;
    }
    if (!_isInitialized) {
      if (kDebugMode) {
        print('AdMob: Cannot create banner ad - AdMob not initialized');
      }
      return null;
    }

    return BannerAd(
      adUnitId: AdHelper.bannerAdUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          if (kDebugMode) print('Banner ad loaded.');
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          if (kDebugMode) print('Banner ad failed to load: $error');
        },
      ),
    );
  }

  AdMobInterstitialHandle? _interstitialAd;
  int _numInterstitialLoadAttempts = 0;
  bool _interstitialLoading = false;
  static const int maxFailedLoadAttempts = 3;

  /// Whether a loaded interstitial is ready to show (TEST4).
  @visibleForTesting
  bool get hasInterstitialReady => _interstitialAd != null;

  /// How many load attempts have failed since last success (TEST4).
  @visibleForTesting
  int get interstitialLoadAttempts => _numInterstitialLoadAttempts;

  /// Clears interstitial state on the singleton (tests only).
  @visibleForTesting
  void resetInterstitialStateForTests() {
    _interstitialAd = null;
    _numInterstitialLoadAttempts = 0;
    _interstitialLoading = false;
  }

  /// Waits up to [timeout] for an in-flight interstitial load to settle.
  /// Returns immediately when an ad is already loaded or no load is running.
  Future<void> awaitInterstitialReady({
    Duration timeout = const Duration(seconds: 3),
  }) async {
    final deadline = DateTime.now().add(timeout);
    while (_interstitialAd == null &&
        _interstitialLoading &&
        DateTime.now().isBefore(deadline)) {
      await Future<void>.delayed(const Duration(milliseconds: 100));
    }
  }

  void createInterstitialAd() {
    if (!_platform.isSupported) {
      if (kDebugMode) {
        print(
            'AdMob: Cannot create interstitial ad - platform not supported');
      }
      return;
    }
    if (!_isInitialized) {
      if (kDebugMode) {
        print(
            'AdMob: Cannot create interstitial ad - AdMob not initialized');
      }
      return;
    }
    // Idempotent: preloading from several screens must not churn loads.
    if (_interstitialAd != null || _interstitialLoading) return;

    _interstitialLoading = true;
    _platform.loadInterstitial(
      adUnitId: AdHelper.interstitialAdUnitId,
      onLoaded: (ad) {
        _interstitialLoading = false;
        _interstitialAd = ad;
        _numInterstitialLoadAttempts = 0;
      },
      onFailed: (_) {
        _interstitialLoading = false;
        _numInterstitialLoadAttempts += 1;
        _interstitialAd = null;
        if (_numInterstitialLoadAttempts < maxFailedLoadAttempts) {
          createInterstitialAd();
        }
      },
    );
  }

  void showInterstitialAd() {
    if (!_platform.isSupported) {
      if (kDebugMode) {
        print('AdMob: Cannot show interstitial ad - platform not supported');
      }
      return;
    }
    if (!_isInitialized) {
      if (kDebugMode) {
        print('AdMob: Cannot show interstitial ad - AdMob not initialized');
      }
      return;
    }
    if (_interstitialAd == null) {
      if (kDebugMode) print('AdMob: No interstitial ad available to show');
      return;
    }

    final ad = _interstitialAd!;
    // Consume before show: onDismissed/onFailedToShow preload the next ad,
    // and a post-show null assignment would clobber that fresh load.
    _interstitialAd = null;
    ad.setFullScreenCallbacks(
      onShowed: () {
        if (kDebugMode) print('ad onAdShowedFullScreenContent.');
      },
      onDismissed: () {
        ad.dispose();
        createInterstitialAd();
      },
      onFailedToShow: () {
        ad.dispose();
        createInterstitialAd();
      },
    );
    ad.show();
  }

  // Track interstitial ad views per day (max 3 per day per prd.md section 9.2)
  static const int maxInterstitialAdsPerDay = 3;
  static const String _interstitialCountKey = 'interstitial_ad_count';
  static const String _interstitialDateKey = 'interstitial_ad_date';

  Future<bool> canShowInterstitialAd() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now().toIso8601String().split('T')[0]; // YYYY-MM-DD
    final lastShownDate = prefs.getString(_interstitialDateKey);

    if (lastShownDate != today) {
      // Reset count for new day
      await prefs.setString(_interstitialDateKey, today);
      await prefs.setInt(_interstitialCountKey, 0);
      return true;
    }

    final count = prefs.getInt(_interstitialCountKey) ?? 0;
    return count < maxInterstitialAdsPerDay;
  }

  Future<void> recordInterstitialAdShown() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now().toIso8601String().split('T')[0];
    final count = prefs.getInt(_interstitialCountKey) ?? 0;

    await prefs.setString(_interstitialDateKey, today);
    await prefs.setInt(_interstitialCountKey, count + 1);
  }

  Future<void> showInterstitialAdIfAllowed() async {
    if (!_platform.isSupported) {
      if (kDebugMode) {
        print('AdMob: Cannot show interstitial ad - platform not supported');
      }
      return;
    }
    if (!_isInitialized) {
      if (kDebugMode) {
        print('AdMob: Cannot show interstitial ad - AdMob not initialized');
      }
      return;
    }

    final canShow = await canShowInterstitialAd();
    if (!canShow) {
      if (kDebugMode) print('AdMob: Daily interstitial ad limit reached');
      return;
    }

    if (_interstitialAd == null) {
      if (kDebugMode) print('AdMob: No interstitial ad available to show');
      return;
    }

    final ad = _interstitialAd!;
    // Consume before show (see showInterstitialAd).
    _interstitialAd = null;
    ad.setFullScreenCallbacks(
      onShowed: () async {
        await recordInterstitialAdShown();
        if (kDebugMode) print('Interstitial ad shown. Daily count updated.');
      },
      onDismissed: () {
        ad.dispose();
        createInterstitialAd();
      },
      onFailedToShow: () {
        ad.dispose();
        createInterstitialAd();
      },
    );
    await ad.show();
  }

  NativeAd? createNativeAd() {
    if (!_platform.isSupported) {
      if (kDebugMode) {
        print('AdMob: Cannot create native ad - platform not supported');
      }
      return null;
    }
    if (!_isInitialized) {
      if (kDebugMode) {
        print('AdMob: Cannot create native ad - AdMob not initialized');
      }
      return null;
    }

    return NativeAd(
      adUnitId: AdHelper.nativeAdUnitId,
      factoryId: 'adFactoryExample',
      request: const AdRequest(),
      listener: NativeAdListener(
        onAdLoaded: (ad) {
          if (kDebugMode) print('Native ad loaded.');
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          if (kDebugMode) print('Native ad failed to load: $error');
        },
      ),
    );
  }
}
