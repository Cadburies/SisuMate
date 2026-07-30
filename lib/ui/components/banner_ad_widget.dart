import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../../core/di.dart';
import '../../services/admob_service.dart';

/// Free-tier banner. Pro → shrink.
///
/// RT2: AdMob's Chromium WebView can log a one-shot Adreno shader-cache miss on
/// first paint — third-party/driver noise, no app-level shader fix. We still
/// **defer** create/load until after the first frame so it does not compete with
/// Flutter's initial paint, and **collapse to zero height** while loading or on
/// failure (SUG4) so empty grey "Ad" chrome never holds layout space.
class BannerAdWidget extends ConsumerStatefulWidget {
  const BannerAdWidget({super.key});

  @override
  ConsumerState<BannerAdWidget> createState() => _BannerAdWidgetState();
}

class _BannerAdWidgetState extends ConsumerState<BannerAdWidget> {
  BannerAd? _bannerAd;
  bool _isAdLoaded = false;
  bool _loadFailed = false;

  @override
  void initState() {
    super.initState();
    // After first frame + short delay: avoids stacking AdMob WebView first
    // paint on the same vsync as home's initial Flutter layout (RT2 window).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future<void>.delayed(const Duration(milliseconds: 400), () {
        if (mounted) _loadBannerAd();
      });
    });
  }

  /// AdMob may still be initializing after first frame (RT1 deferred init).
  Future<void> _loadBannerAd() async {
    final adMobService = AdMobService();
    await adMobService.init();
    if (!mounted) return;

    final ad = adMobService.createBannerAd();
    if (ad == null) {
      if (mounted) setState(() => _loadFailed = true);
      return;
    }

    _bannerAd = ad;
    try {
      await _bannerAd!.load();
      if (mounted) setState(() => _isAdLoaded = true);
    } catch (_) {
      _bannerAd?.dispose();
      _bannerAd = null;
      if (mounted) setState(() => _loadFailed = true);
    }
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isProAsync = ref.watch(isProProvider);

    return isProAsync.when(
      data: (isPro) {
        if (isPro) return const SizedBox.shrink();
        // Collapse until a real ad is ready; collapse on failure (SUG4).
        if (_loadFailed || !_isAdLoaded || _bannerAd == null) {
          return const SizedBox.shrink();
        }
        return Container(
          alignment: Alignment.center,
          width: _bannerAd!.size.width.toDouble(),
          height: _bannerAd!.size.height.toDouble(),
          child: AdWidget(ad: _bannerAd!),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
    );
  }
}
