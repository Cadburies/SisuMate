title: Free GRIB download
desc: Get free GRIB weather files for an area: direct NOAA GFS wind and wave downloads, or a low-bandwidth Saildocs email request.
layer: ux
keywords: grib, download, noaa, gfs, saildocs, email, satellite, low bandwidth
kind: screen
looks: "Free GRIB download" with area and forecast hours, GFS wind and wave download buttons, and a Saildocs query with Copy and Open in email app.
reach: text:Weather > tip:Free GRIB download
needs: -
action: Download directly when online, or send the Saildocs email from a slow or satellite connection.
expect: "Download free GFS wind for this area" and the Saildocs query are shown.
uses: system/network/grib
script: weather
source: lib/ui/weather/grib_request_screen.dart
