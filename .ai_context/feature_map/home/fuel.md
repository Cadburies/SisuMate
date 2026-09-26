title: Fuel & Water
desc: Log fuel and water fills and see totals, spend, burn rate and range.
layer: ux
keywords: fuel, water, diesel, fill, tank, burn, range, litres, consumption
kind: screen
looks: "Fuel & Water Log" with Fuel, Water and Spend totals, a "Burn & range" card and the list of fills; + button bottom-right.
reach: text:Fuel & Water
needs: -
action: Tap a fill to see or edit it; + logs a new one.
expect: "No entries yet" on a fresh install.
uses: system/logic/fuel_burn_estimate
script: fuel
source: lib/ui/fuel/fuel_screen.dart (FuelScreen)
