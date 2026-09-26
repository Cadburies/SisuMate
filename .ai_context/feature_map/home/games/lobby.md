title: Game lobby
desc: Where a multiplayer game is set up: enter your name, then host a game or join one on the same Wi-Fi.
layer: ux
keywords: lobby, host, join, multiplayer, wifi, players, seats
kind: screen
looks: "<Game> — Multiplayer" with a "Your name" field, "Host Game" and "Join a Game".
reach: text:Games > text:Multiplayer Mode > text:Dudo
needs: -
action: Host starts a game others can find; Join scans for hosted games nearby.
expect: "Host Game" and "Join a Game" are shown.
uses: system/lan/game_lan
script: games
source: lib/ui/games/lobby/lobby_screen.dart (GameLobbyScreen)
