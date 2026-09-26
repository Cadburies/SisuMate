title: Weather
desc: Marine forecast for any place: wind, waves and pressure, with saved places, a passage planner, departure-window scoring and GRIB files.
layer: ux
keywords: weather, forecast, wind, waves, gribs, marine, passage
kind: screen
looks: Map and location fields (place name, latitude, longitude), Use GPS, a bookmark button and "Get forecast"; title-bar buttons for passage planner, departure window, GRIB viewer and GRIB download.
reach: text:Weather
needs: -
action: Set a place (GPS, map, search or coordinates) and get its forecast; open the planning tools from the title bar.
expect: "Get forecast" and the location fields are shown.
uses: -
script: weather
source: lib/ui/weather/weather_screen.dart (WeatherScreen)
