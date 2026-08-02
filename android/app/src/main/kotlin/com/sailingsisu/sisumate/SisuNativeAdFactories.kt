package com.sailingsisu.sisumate

import android.view.LayoutInflater
import android.view.View
import android.widget.Button
import android.widget.ImageView
import android.widget.TextView
import com.google.android.gms.ads.nativead.NativeAd
import com.google.android.gms.ads.nativead.NativeAdView
import io.flutter.plugins.googlemobileads.NativeAdFactory

/** Shared binding for the tile-styled native ad layouts (#124). */
private object SisuNativeAdBinder {
    fun bind(adView: NativeAdView, nativeAd: NativeAd) {
        val headline = adView.findViewById<TextView>(R.id.ad_headline)
        headline.text = nativeAd.headline
        adView.headlineView = headline

        val body = adView.findViewById<TextView>(R.id.ad_body)
        if (nativeAd.body == null) {
            body.visibility = View.GONE
        } else {
            body.text = nativeAd.body
            body.visibility = View.VISIBLE
        }
        adView.bodyView = body

        val icon = adView.findViewById<ImageView?>(R.id.ad_icon)
        if (icon != null) {
            val iconAsset = nativeAd.icon
            if (iconAsset == null) {
                icon.visibility = View.GONE
            } else {
                icon.setImageDrawable(iconAsset.drawable)
                icon.visibility = View.VISIBLE
            }
            adView.iconView = icon
        }

        val cta = adView.findViewById<Button?>(R.id.ad_cta)
        if (cta != null) {
            if (nativeAd.callToAction == null) {
                cta.visibility = View.GONE
            } else {
                cta.text = nativeAd.callToAction
                cta.visibility = View.VISIBLE
            }
            adView.callToActionView = cta
        }

        val media = adView.findViewById<com.google.android.gms.ads.nativead.MediaView?>(R.id.ad_media)
        if (media != null) {
            adView.mediaView = media
        }

        adView.setNativeAd(nativeAd)
    }
}

/** Full-width row matching the checklist/maintenance/safety item tiles. */
class SisuItemTileNativeAdFactory(private val layoutInflater: LayoutInflater) :
    NativeAdFactory {
    override fun createNativeAd(
        nativeAd: NativeAd,
        customOptions: MutableMap<String, Any>?,
    ): NativeAdView {
        val adView =
            layoutInflater.inflate(R.layout.native_ad_item_tile, null) as NativeAdView
        SisuNativeAdBinder.bind(adView, nativeAd)
        return adView
    }
}

/** Two-column grid card matching the cocktails/Chef recipe cards. */
class SisuCocktailTileNativeAdFactory(private val layoutInflater: LayoutInflater) :
    NativeAdFactory {
    override fun createNativeAd(
        nativeAd: NativeAd,
        customOptions: MutableMap<String, Any>?,
    ): NativeAdView {
        val adView =
            layoutInflater.inflate(R.layout.native_ad_cocktail_tile, null) as NativeAdView
        SisuNativeAdBinder.bind(adView, nativeAd)
        return adView
    }
}
