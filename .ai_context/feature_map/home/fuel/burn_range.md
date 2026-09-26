title: Burn rate and range
desc: Estimates litres per day and days left for each tank from your recent fills. One fill is not enough: it says "unknown".
layer: ux
keywords: burn, range, consumption, days left, litres per day, estimate
kind: card
looks: "Burn & range" card on Fuel & Water with one line per tank.
reach: text:Fuel & Water > tip:Add fuel log > type:Volume (L)=40 > type:Notes=Marina fill > text:Save
needs: tier=pro
action: Recalculates from the last few fills each time you log one; assumes you top up to full.
expect: After one fill it reads "Fuel · unknown — log another fill".
uses: system/logic/fuel_burn_estimate
script: fuel
source: lib/ui/fuel/fuel_screen.dart (FuelScreen); lib/services/fuel_burn_estimator.dart (FuelBurnEstimator)
