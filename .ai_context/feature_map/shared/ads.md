title: Ads (Free version)
desc: The Free version shows a banner at the bottom of some screens, small native ads in some lists, and an occasional full-screen ad; Pro has none.
layer: ux
keywords: ads, advert, banner, free, remove ads, interstitial
kind: banner
looks: A banner ad along the bottom of Home and module screens, ad cards inside some lists.
reach: -
needs: tier=free · platform=device
action: Shows ads from AdMob on a real phone; upgrading to Pro removes them.
expect: A banner ad appears at the bottom of Home on Free.
uses: system/ads/admob
script: -
source: lib/ui/components/banner_ad_widget.dart (BannerAdWidget); lib/ui/components/native_ad_widget.dart (NativeAdWidget); lib/ui/components/ad_slots.dart
