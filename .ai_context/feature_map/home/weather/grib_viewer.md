title: GRIB viewer
desc: View downloaded or imported GRIB weather files on the map, fully offline.
layer: ux
keywords: grib, viewer, wind file, offline weather, import
kind: screen
looks: "GRIB viewer" with buttons to request a GRIB or import a GRIB file.
reach: text:Weather > tip:GRIB viewer
needs: -
action: Open a GRIB to see wind and waves over time; request or import one from the title bar.
expect: The "GRIB viewer" opens.
uses: system/network/grib
script: weather
source: lib/ui/weather/grib_viewer_screen.dart
