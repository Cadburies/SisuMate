package com.sailingsisu.sisumate

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugins.googlemobileads.GoogleMobileAdsPlugin

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        // #124: tile-styled native ads — one factory per list style, ids must
        // match lib/services/admob_service.dart's kNativeAdFactory* constants.
        GoogleMobileAdsPlugin.registerNativeAdFactory(
            flutterEngine,
            "sisu_item_tile",
            SisuItemTileNativeAdFactory(layoutInflater),
        )
        GoogleMobileAdsPlugin.registerNativeAdFactory(
            flutterEngine,
            "sisu_cocktail_tile",
            SisuCocktailTileNativeAdFactory(layoutInflater),
        )
    }

    override fun cleanUpFlutterEngine(flutterEngine: FlutterEngine) {
        GoogleMobileAdsPlugin.unregisterNativeAdFactory(flutterEngine, "sisu_item_tile")
        GoogleMobileAdsPlugin.unregisterNativeAdFactory(flutterEngine, "sisu_cocktail_tile")
        super.cleanUpFlutterEngine(flutterEngine)
    }
}
