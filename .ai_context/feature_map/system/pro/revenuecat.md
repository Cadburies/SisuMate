title: Pro subscription status
desc: Whether this device has Sisu Mate Pro, from the RevenueCat entitlement, with tester-track time-limited Pro and a debug-only force switch.
layer: pro
keywords: pro, subscription, entitlement, revenuecat, purchase, restore, tester
kind: service
looks: -
reach: app start and after purchase/restore; read everywhere through isProProvider
needs: -
action: isPro() is authoritative; tester builds get Pro until FORCE_PRO_UNTIL; kForceProForTesting applies to debug builds only.
expect: Pro-only features unlock exactly when the entitlement (or tester window) is active.
uses: -
script: test/revenuecat_pro_status_test.dart
source: lib/services/revenuecat_service.dart (RevenueCatService, kForceProForTesting)
