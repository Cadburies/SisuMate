title: PredictWind DataHub and Home Assistant
desc: Reads boat position and instruments from a PredictWind DataHub (local or internet) or Home Assistant, with gateway discovery and connection tests.
layer: network
keywords: datahub, predictwind, home assistant, gateway, discovery, instruments
kind: service
looks: -
reach: Anchor Alarm, Weather position, polar sampling; setup in Boat instruments / GPS
needs: network=online
action: Probes local then internet addresses, reports status, and returns boat data.
expect: With a gateway configured, position and wind come from the boat.
uses: system/platform/boat_position
script: test/predictwind_datahub_service_test.dart
source: lib/services/predictwind_datahub_service.dart (PredictWindDatahubService, GatewayDiscoveryResult); lib/services/home_assistant_service.dart (HomeAssistantService)
