title: Upgrade to Pro
desc: Opens the Sisu Mate Pro upgrade page from the menu.
layer: ux
keywords: upgrade, pro, subscribe, buy, premium, unlock
kind: menu
looks: "Upgrade to Pro / Unlock all features" row in the menu (greyed out when you already have Pro).
reach: tip:Menu > text:Upgrade to Pro
needs: tier=free
action: Opens the upgrade page.
expect: The "Upgrade to Sisu Mate Pro" page opens.
uses: shared/paywall
script: home
source: lib/ui/components/common_drawer.dart (ProUpgradeSection)
