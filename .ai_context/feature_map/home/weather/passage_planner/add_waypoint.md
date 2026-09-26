title: Add a waypoint
desc: Adds another waypoint to the passage route.
layer: ux
keywords: waypoint, add, route, point, mark
kind: button
looks: "+" location button in the Passage Planner title bar.
reach: text:Weather > tip:Passage planner > tip:Add waypoint
needs: -
action: Adds a waypoint that you can then place on the map.
expect: The route gets another numbered waypoint.
uses: -
script: weather
source: lib/ui/weather/passage_planner_screen.dart (PassagePlannerScreen)
