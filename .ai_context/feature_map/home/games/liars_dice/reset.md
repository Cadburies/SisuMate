title: Reset the game (Liar's Dice)
desc: Clears the table and returns to setup.
layer: ux
keywords: reset, new game, restart
kind: button
looks: Reset button in the title bar.
reach: text:Games > text:Liar's Dice > tip:Reset game
needs: -
action: Returns to "Add Players".
expect: "Add Players (2–10)" is shown.
uses: -
script: game_liars_dice
source: lib/ui/games/games/liars_dice/screen.dart (LiarsDiceScreen)
