import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sisu_mate/services/admob_service.dart';

void main() {
  group('AdMobService interstitial daily limit', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('allows showing an ad when nothing has been recorded yet', () async {
      final service = AdMobService();
      expect(await service.canShowInterstitialAd(), isTrue);
    });

    test('allows up to maxInterstitialAdsPerDay ads, then blocks', () async {
      final service = AdMobService();
      for (var i = 0; i < AdMobService.maxInterstitialAdsPerDay; i++) {
        expect(await service.canShowInterstitialAd(), isTrue);
        await service.recordInterstitialAdShown();
      }
      expect(await service.canShowInterstitialAd(), isFalse);
    });

    test('resets the count on a new day', () async {
      final service = AdMobService();
      final prefs = await SharedPreferences.getInstance();
      // Simulate the limit already hit yesterday.
      await prefs.setString('interstitial_ad_date', '2020-01-01');
      await prefs.setInt(
          'interstitial_ad_count', AdMobService.maxInterstitialAdsPerDay);

      expect(await service.canShowInterstitialAd(), isTrue);
    });
  });
}
