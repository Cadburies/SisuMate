title: Weather routing (isochrones)
desc: Computes the fastest sailing route using the boat's polar and the forecast wind field.
layer: logic
keywords: routing, isochrone, fastest route, polar, wind
kind: service
looks: -
reach: Passage Planner → compute route
needs: -
action: Expands isochrones from the start using polar speeds; needs polar data.
expect: A route is returned; without polar data the planner asks for it.
uses: system/platform/polar_collection
script: test/weather_routing_service_test.dart
source: lib/services/weather_routing_service.dart (IsochroneRoute)
