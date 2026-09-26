title: Compute an optimal route
desc: Uses your boat's polar data and the forecast to find the fastest sailing route (isochrones).
layer: ux
keywords: isochrone, routing, fastest route, polar, optimise, weather routing
kind: button
looks: Route button in the Passage Planner title bar.
reach: text:Weather > tip:Passage planner > tip:Compute isochrone route (needs boat polar data)
needs: -
action: Computes the route; without polar data it tells you to add it in Settings first.
expect: With no polar data: "Set boat polar data in Settings (Boat Polar Data) first."
uses: system/logic/weather_routing
script: weather
source: lib/ui/weather/passage_planner_screen.dart (PassagePlannerScreen); lib/services/weather_routing_service.dart
