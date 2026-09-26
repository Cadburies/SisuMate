title: AIS collision alarm
desc: Turns on the AIS collision alarm that warns about vessels on a collision course.
layer: ux
keywords: ais, collision, alarm, traffic, vessels, cpa
kind: toggle
looks: "AIS collision alarm" switch in Settings.
reach: tip:Menu > text:Settings > text:AIS collision alarm
needs: -
action: Toggles the alarm; it needs AIS data from the boat's instruments.
expect: The switch changes state.
uses: system/platform/nmea
script: settings
source: lib/ui/settings/settings_screen.dart (SettingsScreen)
