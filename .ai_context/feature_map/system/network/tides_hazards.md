title: Tides and marine hazards
desc: Tide and current predictions for nearby stations and marine hazard alerts for the area.
layer: network
keywords: tides, currents, hazards, warnings, alerts
kind: service
looks: -
reach: Weather and passage planning views
needs: network=online
action: Fetches tide/current predictions and hazard alerts for the chosen place.
expect: Tide times and any active hazard alerts are shown for the area.
uses: -
script: test/tide_service_test.dart
source: lib/services/tide_service.dart (TideService); lib/services/marine_hazard_service.dart (MarineHazardService)
