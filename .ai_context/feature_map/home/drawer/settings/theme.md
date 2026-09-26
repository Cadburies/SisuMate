title: Theme
desc: Switch between the dark and light look of the app.
layer: ux
keywords: theme, dark mode, light mode, appearance, night
kind: menu
looks: "Theme" row under Appearance with a picker for Light Theme and Dark Theme.
reach: tip:Menu > text:Settings > tip:Choose theme
needs: -
action: Pick a theme; it is remembered.
expect: "Light Theme" and "Dark Theme" are offered.
uses: -
script: settings
source: lib/ui/settings/settings_screen.dart (SettingsScreen)
