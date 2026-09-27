title: Units and conversions
desc: Converts stored metric values to the user's chosen units (volume, temperature, wind, speed, depth, distance) with Marine/US/Metric presets.
layer: logic
keywords: units, conversion, metric, imperial, knots, litres
kind: service
looks: -
reach: every screen that shows a measurement; set in Settings → Units
needs: -
action: The database stays metric; display converts per preference.
expect: 0, null and huge values convert without errors.
uses: -
script: test/unit_converter_test.dart
source: lib/core/units.dart (UnitConverter, AppUnitPrefs)
