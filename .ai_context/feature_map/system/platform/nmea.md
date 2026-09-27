title: NMEA instruments (YDWG gateway) and failover
desc: Reads NMEA 0183 sentences from a Yacht Devices YDWG gateway over TCP, parses position/wind/depth/speed, and fails over between instrument sources.
layer: platform
keywords: nmea, ydwg, yacht devices, instruments, sentences, failover
kind: service
looks: -
reach: whenever instruments are read (anchor, weather position, polar sampling)
needs: platform=device
action: Connects to the gateway host (default port 1456), parses sentences, and picks the freshest healthy source.
expect: Instrument readings with a source label; stale sources are skipped.
uses: -
script: test/nmea_sentence_parser_test.dart
source: lib/services/nmea_sentence_parser.dart (NmeaSentenceParser); lib/services/ydwg_nmea_service.dart (YdwgNmeaService); lib/services/boat_instrument_failover_service.dart (BoatInstrumentFailoverService)
