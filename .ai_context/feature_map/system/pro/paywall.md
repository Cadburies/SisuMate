title: Paywall presentation
desc: Opens the upgrade page (not a route: a pushed page) from any Pro gate or the menu, and handles purchase and restore.
layer: pro
keywords: paywall, upgrade, purchase, restore, gate
kind: service
looks: -
reach: Upgrade to Pro in menus, "Pro Required" dialogs, Free banners
needs: -
action: showPaywall pushes the paywall; never called with a disposed context after an async gap.
expect: The upgrade page opens from every gate.
uses: system/pro/revenuecat
script: test/pro_free_gate_matrix_test.dart
source: lib/services/revenuecat_service.dart (showPaywall); lib/ui/paywall/paywall_screen.dart (PaywallScreen)
