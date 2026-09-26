title: Main menu
desc: The menu that slides in from the right on Home: settings, your account, data tools, Pro and About.
layer: ux
keywords: menu, drawer, hamburger, options, settings, account
kind: drawer
looks: Panel from the right titled "Sisu Mate" with Settings, Account, Data Management, Upgrade to Pro and About sections.
reach: tip:Menu
needs: -
action: Opens the menu. Every module screen has a similar menu with its own filters above these shared sections.
expect: The menu shows "Settings" and "Data Management".
uses: -
script: home
source: lib/ui/home/home_screen.dart (_buildEndDrawer); lib/ui/components/common_drawer.dart
