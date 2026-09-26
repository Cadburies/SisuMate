title: Host a multiplayer game
desc: Host a game on this phone: others on the same Wi-Fi can join, and you can add computer players with a skill level and style.
layer: ux
keywords: host, start game, add ai, seats, skill, style
kind: button
looks: "Host Game" in the lobby; then a player list with "Add AI", Skill and Style chips, and Start.
reach: text:Games > text:Multiplayer Mode > text:Dudo > type:e.g. Frik=Skipper > text:Host Game
needs: platform=device
action: Broadcasts the game on the local network; Start begins play once players have joined.
expect: The player list shows you as host, with "Add AI" and Start.
uses: system/lan/game_lan
script: scripts/test18_rc_play.sh
source: lib/ui/games/lobby/lobby_screen.dart (GameLobbyScreen)
