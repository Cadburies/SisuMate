title: Units
desc: Choose how values are shown: a Marine, US or Metric preset, or each unit (volume, temperature, wind, speed, depth, distance) separately.
layer: ux
keywords: units, metric, imperial, us, knots, litres, gallons, feet, meters
kind: chip
looks: Units section with Marine, US and Metric chips, then one row per quantity.
reach: tip:Menu > text:Settings > text:US
needs: -
action: A preset sets every unit at once; the database always stays metric.
expect: Values across the app switch to the chosen units.
uses: -
script: settings
source: lib/ui/settings/settings_screen.dart (SettingsScreen)
