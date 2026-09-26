title: Roll and declare a hand
desc: On your turn, roll (holding any dice you want to keep), then declare a hand rank and face, which may be a bluff.
layer: ux
keywords: roll, hold, declare, hand, rank, bluff
kind: button
looks: "Roll Dice", "Tap to hold a die before rolling", Select Rank / Select Face, and "Declare".
reach: text:Games > text:Liar's Dice > text:Add Human Player > text:Add AI Player > text:Start Game
needs: -
action: Roll, choose what to declare and tap Declare; the next player must accept or challenge.
expect: Your declared hand is shown and play passes on.
uses: system/ai/game_ai
script: game_liars_dice
source: lib/ui/games/games/liars_dice/screen.dart (LiarsDiceScreen)
