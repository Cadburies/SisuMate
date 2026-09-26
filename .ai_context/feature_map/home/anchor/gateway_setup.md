title: Instrument gateway setup
desc: Connect Sisu Mate to the boat's instruments through a PredictWind DataHub or a Yacht Devices gateway, locally or over the internet.
layer: ux
keywords: gateway, datahub, ydwg, nmea, instruments, predictwind, connect
kind: screen
looks: "Gateway setup" button next to the instrument status; the setup screen has DataHub and YDWG sections with Discover, Test and Save.
reach: text:Anchor Alarm > tip:Gateway setup
needs: platform=device
action: Discover finds a reachable gateway; Test checks the connection; Save stores the addresses and logins.
expect: The gateway setup screen opens with DataHub and YDWG sections.
uses: system/platform/nmea
script: test/anchor_gateway_setup_screen_test.dart
source: lib/ui/anchor/anchor_gateway_setup_screen.dart (AnchorGatewaySetupScreen)
