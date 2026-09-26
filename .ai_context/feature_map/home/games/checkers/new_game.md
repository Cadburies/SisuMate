title: New game (Checkers)
desc: Starts a fresh game of Checkers.
layer: ux
keywords: new game, restart, reset
kind: button
looks: Refresh button in the title bar.
reach: text:Games > text:Checkers > tip:New game
needs: -
action: Resets the board.
expect: "Your turn — tap a red piece to select it." again.
uses: -
script: game_checkers
source: lib/ui/games/games/checkers/screen.dart (CheckersScreen)
