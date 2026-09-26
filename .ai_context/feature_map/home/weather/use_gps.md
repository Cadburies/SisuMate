title: Use my location
desc: Fills the weather location from the boat's instruments or the phone's GPS.
layer: ux
keywords: gps, my location, current position, locate
kind: button
looks: "Use GPS" button (and a location button in the title bar); shows "Locating..." while it works.
reach: text:Weather > tip:Use my location
needs: platform=device
action: Asks for location permission if needed, then fills latitude and longitude.
expect: The coordinates fill in with the current position.
uses: system/platform/boat_position
script: -
source: lib/ui/weather/weather_screen.dart (_useDeviceLocation); lib/services/boat_position_service.dart
