title: Boat polar data
desc: Your boat's speed at each wind angle and strength: learned automatically while sailing, improvable offline or with AI, and editable by hand.
layer: ux
keywords: polar, boat speed, performance, twa, tws, sailing data, eta
kind: dialog
looks: "Boat Polar Data" row opens a dialog with the stored sample count, Improve offline, Improve with AI, Open diagram, Add row and Save.
reach: tip:Menu > text:Settings > tip:Choose active boat > text:My Boat > text:Boat Polar Data
needs: -
action: Samples are collected under sail in the background; Improve offline cleans them up; the polar feeds ETAs and routing.
expect: "Under-sail samples stored: 0" with "Improve offline" is shown.
uses: system/platform/polar_collection
script: settings
source: lib/ui/settings/boat_polar_dialog.dart
