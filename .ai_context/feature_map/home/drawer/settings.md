title: Settings
desc: App and boat settings: account, active boat, AI keys, boat polar, theme, units, email and sharing, instrument gateways, sync status, alarms and reset.
layer: ux
keywords: settings, preferences, options, configuration, units, theme, boat
kind: screen
looks: "Settings" page with sections: Account, Boats, Appearance, Units, Email & Sharing, Boat instruments / GPS and more.
reach: tip:Menu > text:Settings
needs: -
action: Change any setting; boat-specific rows (AI keys, polar) appear once a boat is active.
expect: The Account, Boats, Appearance and Units sections are shown.
uses: -
script: settings
source: lib/ui/settings/settings_screen.dart (SettingsScreen)
