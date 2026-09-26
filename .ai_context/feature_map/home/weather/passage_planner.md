title: Passage planner
desc: Plan a route by waypoints and see distance, ETA, fuel needed and the forecast along the way.
layer: ux
keywords: passage, route, waypoints, eta, distance, fuel, plan
kind: screen
looks: "Passage Planner" with a map of numbered waypoints, Distance / ETA / Fuel figures, Waypoints and Route forecast sections.
reach: text:Weather > tip:Passage planner
needs: -
action: Add or move waypoints; tools in the title bar compute a polar route or give an AI safety briefing.
expect: Distance, ETA and Fuel are shown for the route.
uses: -
script: weather
source: lib/ui/weather/passage_planner_screen.dart (PassagePlannerScreen)
