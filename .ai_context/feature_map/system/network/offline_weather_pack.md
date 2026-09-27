title: Offline weather pack
desc: Keeps the last forecasts for saved places on the device so planning works at sea with no signal.
layer: network
keywords: offline, weather cache, saved places, no signal
kind: service
looks: -
reach: after each successful forecast download; read by departure window and passage briefing
needs: -
action: Stores and serves the most recent bundle per place with its age.
expect: Planners show cached weather when offline instead of failing.
uses: -
script: test/offline_weather_pack_test.dart
source: lib/services/offline_weather_pack.dart (OfflineWeatherPack)
