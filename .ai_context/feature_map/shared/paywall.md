title: Pro upgrade page
desc: The page where you buy or restore Sisu Mate Pro.
layer: ux
keywords: paywall, pro, upgrade, subscribe, purchase, restore, price
kind: screen
looks: "Upgrade to Sisu Mate Pro" page with the Pro plans, a purchase button and Restore.
reach: tip:Menu > text:Upgrade to Pro
needs: tier=free
action: Shows the plans from the store; buying or restoring unlocks Pro on this device. Plans and purchase need a real phone and store account.
expect: The "Upgrade to Sisu Mate Pro" page opens.
uses: system/pro/revenuecat
script: shared_chrome
source: lib/ui/paywall/paywall_screen.dart; lib/services/revenuecat_service.dart (showPaywall)
