title: Ads (AdMob)
desc: Free-tier ads: banner on Home and modules, native ads inside some lists, and an occasional interstitial (e.g. on list completion); all hidden for Pro.
layer: ads
keywords: ads, admob, banner, native, interstitial, free
kind: service
looks: -
reach: screens with ad slots on Free; not supported on the host test platform
needs: tier=free · platform=device
action: Initialises AdMob on supported platforms; ad slots are placed by position; Pro disables all ads.
expect: Free shows ads on a real phone; Pro never does.
uses: system/pro/revenuecat
script: test/admob_service_test.dart
source: lib/services/admob_service.dart (AdMobService); lib/ui/components/ad_slots.dart; lib/services/admob_platform.dart
