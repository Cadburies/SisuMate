title: Import a GRIB file
desc: Open a GRIB file you received by email or downloaded elsewhere.
layer: ux
keywords: import grib, open file, email grib, saildocs
kind: button
looks: Folder button in the GRIB viewer title bar.
reach: text:Weather > tip:GRIB viewer > tip:Import GRIB file
needs: platform=device
action: Opens the phone's file picker and loads the GRIB into the viewer.
expect: The file picker opens; the GRIB then shows on the map.
uses: system/network/grib
script: -
source: lib/ui/weather/grib_viewer_screen.dart
