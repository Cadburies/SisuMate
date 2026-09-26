title: Add players (Liar's Dice)
desc: Add yourself and computer players before starting.
layer: ux
keywords: players, add ai, add human, seats
kind: button
looks: "Add Human Player" and "Add AI Player"; added players are listed.
reach: text:Games > text:Liar's Dice > text:Add Human Player > text:Add AI Player
needs: -
action: Each tap adds a seat; Start Game needs at least two players.
expect: "You" and an AI player are listed.
uses: -
script: game_liars_dice
source: lib/ui/games/games/liars_dice/screen.dart (LiarsDiceScreen)
