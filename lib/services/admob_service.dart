import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../ads/ad_helper.dart';

class AdMobService {
  static bool _isInitialized = false;
  static bool get isInitialized => _isInitialized;

  Future<void> init() async {
    // Only initialize on supported platforms (Android/iOS)
    if (!Platform.isAndroid && !Platform.isIOS) {
      if (kDebugMode) print('AdMob: Skipping initialization - platform not supported (${Platform.operatingSystem})');
      return;
    }

    try {
      await MobileAds.instance.initialize();
      _isInitialized = true;
      if (kDebugMode) print('AdMob: Successfully initialized');
    } catch (e) {
      if (kDebugMode) print('AdMob: Failed to initialize - $e');
      if (kDebugMode) print('AdMob: App will continue without ads');
      _isInitialized = false;
    }
  }

  BannerAd? createBannerAd() {
    if (!Platform.isAndroid && !Platform.isIOS) {
      if (kDebugMode) print('AdMob: Cannot create banner ad - platform not supported');
      return null;
    }
    if (!_isInitialized) {
      if (kDebugMode) print('AdMob: Cannot create banner ad - AdMob not initialized');
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

  InterstitialAd? _interstitialAd;
  int _numInterstitialLoadAttempts = 0;
  static const int maxFailedLoadAttempts = 3;

  void createInterstitialAd() {
    if (!Platform.isAndroid && !Platform.isIOS) {
      if (kDebugMode) print('AdMob: Cannot create interstitial ad - platform not supported');
      return;
    }
    if (!_isInitialized) {
      if (kDebugMode) print('AdMob: Cannot create interstitial ad - AdMob not initialized');
      return;
    }

    InterstitialAd.load(
      adUnitId: AdHelper.interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (InterstitialAd ad) {
          _interstitialAd = ad;
          _numInterstitialLoadAttempts = 0;
        },
        onAdFailedToLoad: (LoadAdError error) {
          _numInterstitialLoadAttempts += 1;
          _interstitialAd = null;
          if (_numInterstitialLoadAttempts < maxFailedLoadAttempts) {
            createInterstitialAd();
          }
        },
      ),
    );
  }

  void showInterstitialAd() {
    if (!Platform.isAndroid && !Platform.isIOS) {
      if (kDebugMode) print('AdMob: Cannot show interstitial ad - platform not supported');
      return;
    }
    if (!_isInitialized) {
      if (kDebugMode) print('AdMob: Cannot show interstitial ad - AdMob not initialized');
      return;
    }
    if (_interstitialAd == null) {
      if (kDebugMode) print('AdMob: No interstitial ad available to show');
      return;
    }

    _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (InterstitialAd ad) {
        if (kDebugMode) print('ad onAdShowedFullScreenContent.');
      },
      onAdDismissedFullScreenContent: (InterstitialAd ad) {
        ad.dispose();
        createInterstitialAd();
      },
      onAdFailedToShowFullScreenContent: (InterstitialAd ad, AdError error) {
        ad.dispose();
        createInterstitialAd();
      },
    );
    _interstitialAd!.show();
    _interstitialAd = null;
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
    if (!Platform.isAndroid && !Platform.isIOS) {
      if (kDebugMode) print('AdMob: Cannot show interstitial ad - platform not supported');
      return;
    }
    if (!_isInitialized) {
      if (kDebugMode) print('AdMob: Cannot show interstitial ad - AdMob not initialized');
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

    _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (InterstitialAd ad) async {
        await recordInterstitialAdShown();
        if (kDebugMode) print('Interstitial ad shown. Daily count updated.');
      },
      onAdDismissedFullScreenContent: (InterstitialAd ad) {
        ad.dispose();
        createInterstitialAd();
      },
      onAdFailedToShowFullScreenContent: (InterstitialAd ad, AdError error) {
        ad.dispose();
        createInterstitialAd();
      },
    );
    _interstitialAd!.show();
    _interstitialAd = null;
  }

  NativeAd? createNativeAd() {
    if (!Platform.isAndroid && !Platform.isIOS) {
      if (kDebugMode) print('AdMob: Cannot create native ad - platform not supported');
      return null;
    }
    if (!_isInitialized) {
      if (kDebugMode) print('AdMob: Cannot create native ad - AdMob not initialized');
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
