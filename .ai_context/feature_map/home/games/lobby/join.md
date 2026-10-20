title: Join a multiplayer game
desc: Find games hosted on the same Wi-Fi and join one.
layer: ux
keywords: join, find game, scan, nearby, wifi
kind: button
looks: "Join a Game" in the lobby; lists games found nearby as "<game> <host>:<port>".
reach: text:Games > text:Multiplayer Mode > text:Dudo > text:Join a Game
needs: platform=device
action: Scans the local network; tap a found game, then type the 6-digit join code shown on the host's phone.
expect: Hosted games nearby are listed. A wrong code sends you back with a message. After joining you wait for the host to start. The last code you used is filled in, so you can rejoin after the app closes.
uses: system/lan/game_lan
script: scripts/test18_rc_play.sh
source: lib/ui/games/lobby/lobby_screen.dart (GameLobbyScreen)
