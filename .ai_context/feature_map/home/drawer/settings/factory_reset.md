title: Factory reset (Settings)
desc: Resets the database to the factory state after confirming.
layer: ux
keywords: factory reset, reset, restore, wipe, start over
kind: dialog
looks: "Factory Reset / Reset database to factory state" row; opens a confirmation with Cancel and Reset.
reach: tip:Menu > text:Settings > text:Factory Reset
needs: -
action: Reset restores bundled content; Cancel closes.
expect: The "Factory Reset" confirmation is shown.
uses: home/drawer/reset_to_factory
script: settings
source: lib/ui/settings/settings_screen.dart (SettingsScreen)
