import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../../core/di.dart';
import '../../services/admob_service.dart';

/// Free-tier native ad. Pro → shrink.
///
/// Same RT2/SUG4 policy as [BannerAdWidget]: defer load past first frame;
/// zero height until loaded; collapse on failure (no grey placeholder).
class NativeAdWidget extends ConsumerStatefulWidget {
  const NativeAdWidget({super.key});

  @override
  ConsumerState<NativeAdWidget> createState() => _NativeAdWidgetState();
}

class _NativeAdWidgetState extends ConsumerState<NativeAdWidget> {
  NativeAd? _nativeAd;
  bool _isAdLoaded = false;
  bool _loadFailed = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future<void>.delayed(const Duration(milliseconds: 400), () {
        if (mounted) _loadNativeAd();
      });
    });
  }

  Future<void> _loadNativeAd() async {
    final adMobService = AdMobService();
    await adMobService.init();
    if (!mounted) return;

    final ad = adMobService.createNativeAd();
    if (ad == null) {
      if (mounted) setState(() => _loadFailed = true);
      return;
    }

    _nativeAd = ad;
    try {
      await _nativeAd!.load();
      if (mounted) setState(() => _isAdLoaded = true);
    } catch (_) {
      _nativeAd?.dispose();
      _nativeAd = null;
      if (mounted) setState(() => _loadFailed = true);
    }
  }

  @override
  void dispose() {
    _nativeAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isProAsync = ref.watch(isProProvider);

    return isProAsync.when(
      data: (isPro) {
        if (isPro) return const SizedBox.shrink();
        if (_loadFailed || !_isAdLoaded || _nativeAd == null) {
          return const SizedBox.shrink();
        }
        return ConstrainedBox(
          constraints: const BoxConstraints(
            minWidth: 320,
            minHeight: 90,
            maxWidth: double.infinity,
            maxHeight: 200,
          ),
          child: AdWidget(ad: _nativeAd!),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
    );
  }
}
