title: Offer a double
desc: Offer the AI the doubling cube before you roll; it accepts or drops.
layer: ux
keywords: double, doubling cube, stakes, backgammon
kind: button
looks: "Double ×2" button next to Roll Dice.
reach: text:Games > text:Backgammon > text:Double ×2
needs: -
action: Offers the double; the AI answers after a moment.
expect: "Double offered (1→2). Waiting…", then the AI's answer.
uses: -
script: game_backgammon
source: lib/ui/games/games/backgammon/screen.dart (BackgammonScreen)
