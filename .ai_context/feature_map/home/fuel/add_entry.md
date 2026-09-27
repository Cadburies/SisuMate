title: Log a fuel or water fill
desc: Record a fill: type (fuel or water), date, volume, price, hours motored or distance, and notes. Pro only.
layer: ux
keywords: add, fill, refuel, water, log, diesel, volume, price
kind: fab
looks: Round + button on Fuel & Water; opens "Add Entry".
reach: text:Fuel & Water > tip:Add fuel log
needs: tier=pro (on Free it explains that editing needs Pro)
action: Save adds the fill and updates totals and the burn estimate.
expect: "Add Entry" opens; after Save the totals show the new volume.
uses: -
script: fuel
source: lib/ui/fuel/fuel_screen.dart (FuelScreen); lib/ui/fuel/fuel_screen.dart (AddEditFuelEntryDialog)
