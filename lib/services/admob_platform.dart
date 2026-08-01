import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// TEST4 seam: platform-side ad operations without hard-wiring the Mobile Ads
/// SDK into control-flow unit tests.
abstract class AdMobPlatform {
  bool get isSupported;

  Future<void> initialize();

  /// Loads an interstitial asynchronously.
  void loadInterstitial({
    required String adUnitId,
    required void Function(AdMobInterstitialHandle ad) onLoaded,
    required void Function(Object error) onFailed,
  });
}

/// Loaded interstitial handle (production wraps [InterstitialAd]).
abstract class AdMobInterstitialHandle {
  void setFullScreenCallbacks({
    FutureOr<void> Function()? onShowed,
    FutureOr<void> Function()? onDismissed,
    FutureOr<void> Function()? onFailedToShow,
  });

  Future<void> show();

  void dispose();
}

/// Production [AdMobPlatform] over `google_mobile_ads`.
class LiveAdMobPlatform implements AdMobPlatform {
  const LiveAdMobPlatform();

  @override
  bool get isSupported => Platform.isAndroid || Platform.isIOS;

  @override
  Future<void> initialize() async {
    await MobileAds.instance.initialize();
  }

  @override
  void loadInterstitial({
    required String adUnitId,
    required void Function(AdMobInterstitialHandle ad) onLoaded,
    required void Function(Object error) onFailed,
  }) {
    InterstitialAd.load(
      adUnitId: adUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (InterstitialAd ad) {
          onLoaded(_LiveInterstitialHandle(ad));
        },
        onAdFailedToLoad: (LoadAdError error) {
          onFailed(error);
        },
      ),
    );
  }
}

class _LiveInterstitialHandle implements AdMobInterstitialHandle {
  _LiveInterstitialHandle(this._ad);

  final InterstitialAd _ad;

  @override
  void setFullScreenCallbacks({
    FutureOr<void> Function()? onShowed,
    FutureOr<void> Function()? onDismissed,
    FutureOr<void> Function()? onFailedToShow,
  }) {
    _ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (_) {
        onShowed?.call();
      },
      onAdDismissedFullScreenContent: (_) {
        onDismissed?.call();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        onFailedToShow?.call();
      },
    );
  }

  @override
  Future<void> show() => _ad.show();

  @override
  void dispose() => _ad.dispose();
}

/// In-memory fake for unit tests (TEST4).
class FakeAdMobPlatform implements AdMobPlatform {
  FakeAdMobPlatform({
    this.isSupported = true,
    this.failInitialize = false,
    this.failLoadsUntil = 0,
    this.failShow = false,
  });

  @override
  bool isSupported;

  bool failInitialize;
  int failLoadsUntil;
  bool failShow;

  int initializeCalls = 0;
  int loadCalls = 0;
  int showCalls = 0;

  /// Last loaded handle (if any).
  FakeAdMobInterstitialHandle? lastHandle;

  @override
  Future<void> initialize() async {
    initializeCalls++;
    if (failInitialize) throw Exception('FakeAdMobPlatform: init failed');
  }

  @override
  void loadInterstitial({
    required String adUnitId,
    required void Function(AdMobInterstitialHandle ad) onLoaded,
    required void Function(Object error) onFailed,
  }) {
    loadCalls++;
    if (failLoadsUntil > 0) {
      failLoadsUntil--;
      onFailed(Exception('FakeAdMobPlatform: load failed'));
      return;
    }
    final handle = FakeAdMobInterstitialHandle(this);
    lastHandle = handle;
    onLoaded(handle);
  }
}

class FakeAdMobInterstitialHandle implements AdMobInterstitialHandle {
  FakeAdMobInterstitialHandle(this._platform);

  final FakeAdMobPlatform _platform;

  FutureOr<void> Function()? onShowed;
  FutureOr<void> Function()? onDismissed;
  FutureOr<void> Function()? onFailedToShow;

  @override
  void setFullScreenCallbacks({
    FutureOr<void> Function()? onShowed,
    FutureOr<void> Function()? onDismissed,
    FutureOr<void> Function()? onFailedToShow,
  }) {
    this.onShowed = onShowed;
    this.onDismissed = onDismissed;
    this.onFailedToShow = onFailedToShow;
  }

  @override
  Future<void> show() async {
    _platform.showCalls++;
    if (_platform.failShow) {
      await Future.sync(() => onFailedToShow?.call());
      return;
    }
    await Future.sync(() => onShowed?.call());
    await Future.sync(() => onDismissed?.call());
  }

  @override
  void dispose() {}
}

/// Debug-only helper so print calls stay out of pure fakes.
void adMobDebugLog(String message) {
  if (kDebugMode) print(message);
}
