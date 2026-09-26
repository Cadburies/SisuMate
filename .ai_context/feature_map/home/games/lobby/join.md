title: Join a multiplayer game
desc: Find games hosted on the same Wi-Fi and join one.
layer: ux
keywords: join, find game, scan, nearby, wifi
kind: button
looks: "Join a Game" in the lobby; lists games found nearby as "<game> <host>:<port>".
reach: text:Games > text:Multiplayer Mode > text:Dudo > text:Join a Game
needs: platform=device
action: Scans the local network; tap a found game to join its table.
expect: Hosted games nearby are listed; after joining you wait for the host to start.
uses: system/lan/game_lan
script: scripts/test18_rc_play.sh
source: lib/ui/games/lobby/lobby_screen.dart (GameLobbyScreen)
