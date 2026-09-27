title: Weather forecast service
desc: Fetches marine forecasts (wind, gusts, waves, pressure; ensemble and multi-model) for a place and caches them for offline use and the planning tools.
layer: network
keywords: weather, forecast, wind, waves, marine, ensemble, cache
kind: service
looks: -
reach: Weather "Get forecast", Refresh, and planners that need forecast data
needs: network=online
action: Downloads the forecast bundle, stores it for offline reading, and raises WeatherException on HTTP errors.
expect: The Weather screen shows charts; planners reuse the cached bundle offline.
uses: system/network/offline_weather_pack
script: test/weather_service_test.dart
source: lib/services/weather_service.dart (WeatherService, WeatherBundle, WeatherException)
