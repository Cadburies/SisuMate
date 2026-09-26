title: New game (Backgammon)
desc: Starts a fresh game of Backgammon.
layer: ux
keywords: new game, restart, reset
kind: button
looks: Refresh button in the title bar.
reach: text:Games > text:Backgammon > tip:New game
needs: -
action: Resets the board and the cube.
expect: "Tap \"Roll\" to start your turn." again.
uses: -
script: game_backgammon
source: lib/ui/games/games/backgammon/screen.dart (BackgammonScreen)
