title: Departure window planner
desc: Scores the coming hours and days for leaving, from the cached forecast, so you can pick the best time to go.
layer: ux
keywords: departure, window, when to leave, best time, weather window
kind: screen
looks: "Departure window planner" with scored time slots.
reach: text:Weather > tip:Departure window planner
needs: -
action: Shows the best departure windows; it needs a forecast loaded for the area first.
expect: Without cached weather it says to load a forecast first.
uses: system/logic/departure_window
script: weather
source: lib/ui/weather/departure_window_screen.dart
