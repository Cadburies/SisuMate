title: Departure window scoring
desc: Scores upcoming hours for leaving from the cached forecast (wind, gusts, waves) against comfort thresholds.
layer: logic
keywords: departure window, weather window, when to leave, score
kind: service
looks: -
reach: Departure window planner
needs: -
action: Scores each slot and picks the best windows.
expect: Calm slots score higher than gusty ones.
uses: system/network/offline_weather_pack
script: test/departure_window_scorer_test.dart
source: lib/services/departure_window_scorer.dart (DepartureWindow, DepartureWindowThresholds)
