title: Fuel burn estimate
desc: Per-tank litres/day and days remaining from fill history; single fill → remaining unknown (null), not full.
layer: logic
keywords: fuel, water, burn rate, litres per day, remaining, range, tank
kind: service
looks: -
reach: runs whenever Fuel, Home readiness card, or passage debrief reads fuel logs
needs: -
action: L/day = recency-weighted mean of the last 6 fill intervals per tank.
expect: Estimates per tank; null remaining when there are too few fills.
uses: system/db/fuel_log_repository
script: test/fuel_burn_estimator_test.dart
source: lib/services/fuel_burn_estimator.dart (FuelBurnEstimator.estimate)
