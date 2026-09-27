title: LAN multiplayer games
desc: Hosts and joins games over local Wi-Fi: mDNS (bonsoir) discovery, a WebSocket host running the game, clients sending moves, player joins/leaves, and rejoining the same seat after a drop.
layer: lan
keywords: lan, multiplayer, wifi, bonsoir, mdns, websocket, host, join, rejoin
kind: service
looks: -
reach: Games → Multiplayer Mode → a game → Host Game / Join a Game
needs: platform=device
action: The host broadcasts and runs the authoritative game state; clients render pushed state; leaving an unstarted lobby ends the session.
expect: Joined players appear in the host's lobby; a dropped player can rejoin their seat mid-game.
uses: system/ai/game_ai
script: test/games_multiplayer_lan_test.dart
source: lib/services/lan/game_lan_service.dart (GameLanService); lib/services/lan/lan_engine.dart; lib/services/lan/lan_providers.dart
