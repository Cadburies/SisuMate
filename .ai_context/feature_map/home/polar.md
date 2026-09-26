title: Polar
desc: The boat's polar diagram: how fast it sails at each wind angle and strength, by sea state, learned while sailing.
layer: ux
keywords: polar, diagram, boat speed, performance, curves, sea state
kind: screen
looks: "Polar diagram" with Diagram, Boat and Sea state controls, coverage stats and reset buttons; needs an active boat.
reach: text:Polar
needs: -
action: Shows the curves; Improve offline cleans the samples; reset buttons clear curves per sea state.
expect: With no active boat it says "No active boat — set one in Settings."
uses: home/drawer/settings/boat_polar
script: polar
source: lib/ui/settings/polar_chart_screen.dart (PolarChartScreen)
