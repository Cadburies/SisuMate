title: Add players (Dudo)
desc: Add yourself and computer players to the table before starting.
layer: ux
keywords: players, add ai, add human, seats, table
kind: button
looks: "Add Human Player" and "Add AI Player" on the setup screen; added players are listed ("You", "AI 1"…).
reach: text:Games > text:Dudo > text:Add Human Player > text:Add AI Player
needs: -
action: Each tap adds a seat; Start Game needs at least two players.
expect: "You" and an AI player are listed and Start Game is enabled.
uses: -
script: game_dudo
source: lib/ui/games/games/dudo/screen.dart (DudoScreen)
