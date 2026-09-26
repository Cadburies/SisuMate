title: Polar diagram for the active boat
desc: The polar curves and measured coverage for the active boat, with offline improve and reset.
layer: ux
keywords: polar, coverage, improve offline, reset curves, samples
kind: screen
looks: Coverage line ("Measured coverage: N% …"), Improve offline, and Reset Smooth / Moderate / Rough / all.
reach: tip:Menu > text:Settings > tip:Choose active boat > text:My Boat > text:Polar diagram
needs: -
action: Improve offline or reset curves for one sea state or all.
expect: "Measured coverage: 0% of TWA×TWS cells · 0 samples" on a new boat.
uses: system/platform/polar_collection
script: polar
source: lib/ui/settings/polar_chart_screen.dart (PolarChartScreen)
