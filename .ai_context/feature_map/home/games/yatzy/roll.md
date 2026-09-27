title: Roll the dice (Yatzy)
desc: Rolls all dice that are not held; up to three rolls per turn.
layer: ux
keywords: roll, dice, reroll, turn
kind: button
looks: "Roll Dice" button ("Roll Again" after the first roll).
reach: text:Games > text:Yatzy > text:Roll Dice
needs: -
action: Rolls, then lets you hold dice or pick a category.
expect: "Rolls left: 2" and "Pick a category or hold dice and roll again."
uses: -
script: game_yatzy
source: lib/ui/games/games/yatzy/screen.dart (YatzyScreen)
