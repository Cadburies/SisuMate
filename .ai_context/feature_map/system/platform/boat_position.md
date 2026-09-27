title: Boat position (instruments first, phone GPS fallback)
desc: Gets the best available position and instrument data: boat gateways (DataHub, YDWG, Home Assistant) first, then the phone's GPS if allowed.
layer: platform
keywords: position, gps, location, instruments, failover, fix
kind: service
looks: -
reach: Anchor Alarm, Weather "Use GPS", polar sampling
needs: platform=device
action: fetchBest tries each source in order with a 12 s location time limit and reports which source answered.
expect: A position with its source label, or "Position unavailable" when nothing answers.
uses: system/platform/nmea, system/network/instruments_gateway
script: test/boat_position_service_test.dart
source: lib/services/boat_position_service.dart (BoatPositionService); lib/services/location_service.dart (LocationService)
