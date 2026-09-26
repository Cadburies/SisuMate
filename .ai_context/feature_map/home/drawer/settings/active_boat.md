title: Choose the active boat
desc: Pick which boat the app works on; lists, sync and boat settings follow the active boat.
layer: ux
keywords: active boat, switch boat, select boat, current boat
kind: menu
looks: "Active Boat" row in Settings with a picker button; shows "No boat selected" on a fresh install.
reach: tip:Menu > text:Settings > tip:Choose active boat > text:My Boat
needs: -
action: Choose a boat from the list; the title bars then show its name.
expect: The status line changes to "My Boat • …" and the boat's settings rows appear.
uses: -
script: settings
source: lib/ui/settings/settings_screen.dart (SettingsScreen)
