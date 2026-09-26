title: Boat instruments and GPS
desc: Set up the PredictWind DataHub, the YDWG-02 NMEA gateway and Home Assistant as position and instrument sources.
layer: ux
keywords: instruments, gps, datahub, ydwg, nmea, home assistant, gateway
kind: screen
looks: "Boat instruments / GPS" page with DataHub, YDWG-02 and Home Assistant sections, Discover and Test buttons.
reach: tip:Menu > text:Settings > text:DataHub, YDWG & Home Assistant
needs: -
action: Enter or discover gateway addresses and test them; Anchor, Weather position and polar sampling use them.
expect: "PredictWind DataHub", "YDWG-02 (NMEA gateway)" and "Home Assistant" are shown.
uses: system/platform/nmea
script: settings
source: lib/ui/anchor/anchor_gateway_setup_screen.dart (AnchorGatewaySetupScreen)
