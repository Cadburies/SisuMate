title: Account in Settings
desc: The Account part of Settings: the same Boat account and Join a boat entries as the menu, plus Sign Out and Delete My Account when signed in.
layer: ux
keywords: sign in, login, account, join boat, email, delete account
kind: tile
looks: "Boat account" and "Join a boat" under Account at the top of Settings (signed out).
reach: tip:Menu > text:Settings
needs: auth=none
action: Opens the Boat account or Join a boat screen, the same as the menu.
expect: "Boat account" and "Join a boat" are shown under Account.
uses: home/drawer/account
script: settings
source: lib/ui/settings/settings_screen.dart (SettingsScreen); lib/ui/components/common_drawer.dart (AccountSection)
