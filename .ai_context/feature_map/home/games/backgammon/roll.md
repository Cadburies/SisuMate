title: Roll the dice (Backgammon)
desc: Rolls your two dice to start your turn.
layer: ux
keywords: roll, dice, turn, backgammon
kind: button
looks: "Roll Dice" button under the board.
reach: text:Games > text:Backgammon > text:Roll Dice
needs: -
action: Rolls, then asks you to select a piece to move.
expect: "Rolled N, M. Select a piece to move."
uses: -
script: game_backgammon
source: lib/ui/games/games/backgammon/screen.dart (BackgammonScreen)
