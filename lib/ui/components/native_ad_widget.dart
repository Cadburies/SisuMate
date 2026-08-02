import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../../core/di.dart';
import '../../services/admob_service.dart';

/// Which list-tile style the native ad should render as. Maps 1:1 to the
/// platform-side `NativeAdFactory` ids registered in MainActivity/AppDelegate.
enum NativeAdTileStyle {
  /// Full-width row matching checklist/maintenance/safety item tiles.
  itemTile(kNativeAdFactoryItemTile),

  /// Two-column grid card matching the cocktails/Chef recipe cards.
  cocktailTile(kNativeAdFactoryCocktailTile);

  const NativeAdTileStyle(this.factoryId);
  final String factoryId;
}

/// Free-tier native ad rendered like one of the list's own tiles. Pro → shrink.
///
/// Same RT2/SUG4 policy as [BannerAdWidget]: defer load past first frame;
/// zero height until loaded; collapse on failure (no grey placeholder) —
/// but failures ARE logged in debug (#124: this used to regress silently).
class NativeAdWidget extends ConsumerStatefulWidget {
  const NativeAdWidget({
    super.key,
    this.style = NativeAdTileStyle.itemTile,
    this.contextHint,
  });

  final NativeAdTileStyle style;

  /// Module hint for soft ad-context targeting (see
  /// [AdMobService.createNativeAd]), e.g. `'cocktails'`, `'maintenance'`.
  final String? contextHint;

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

    final ad = adMobService.createNativeAd(
        factoryId: widget.style.factoryId, contextHint: widget.contextHint);
    if (ad == null) {
      if (kDebugMode) {
        print('NativeAdWidget: createNativeAd(${widget.style.factoryId}) '
            'returned null (unsupported platform or not initialized)');
      }
      if (mounted) setState(() => _loadFailed = true);
      return;
    }

    _nativeAd = ad;
    try {
      await _nativeAd!.load();
      if (mounted) setState(() => _isAdLoaded = true);
    } catch (e) {
      if (kDebugMode) {
        print('NativeAdWidget: native ad failed to load '
            '(${widget.style.factoryId}): $e');
      }
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
        return switch (widget.style) {
          NativeAdTileStyle.itemTile => ConstrainedBox(
              constraints: const BoxConstraints(
                minWidth: 320,
                minHeight: 90,
                maxWidth: double.infinity,
                maxHeight: 140,
              ),
              child: AdWidget(ad: _nativeAd!),
            ),
          // The grid cell's aspect ratio (0.55) sizes this; AdWidget must
          // simply fill the cell it's placed in.
          NativeAdTileStyle.cocktailTile => AdWidget(ad: _nativeAd!),
        };
      },
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
    );
  }
}
