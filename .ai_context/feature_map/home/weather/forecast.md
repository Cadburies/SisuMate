title: Get a forecast
desc: Downloads and shows the marine forecast for the chosen place, and caches it for offline use and the planning tools.
layer: ux
keywords: forecast, get forecast, wind, waves, download, marine weather
kind: button
looks: "Get forecast" button under the location fields.
reach: text:Weather > type:Latitude=-33.9 > type:Longitude=18.4 > type:Place name=Cape Town > text:Get forecast
needs: network=online · platform=device
action: Fetches the forecast for the place; with no location set it asks you to set one.
expect: Forecast charts appear; without a location it says "Set a location — Use GPS, tap the map, search a place, or enter coordinates."
uses: system/network/weather
script: -
source: lib/ui/weather/weather_screen.dart (WeatherScreen); lib/services/weather_service.dart
