title: Accept or challenge
desc: When a hand is passed to you, accept it (and try to beat it) or call it a lie.
layer: ux
keywords: accept, challenge, call, liar, reveal
kind: button
looks: "Accept" and "Challenge!" buttons with the declared hand shown.
reach: text:Games > text:Liar's Dice > text:Add Human Player > text:Add AI Player > text:Start Game
needs: -
action: Challenge reveals the dice ("Declared" vs "Actual"); the loser loses a counter.
expect: After a challenge, "Declared" and "Actual" are compared, then "Next round starting…".
uses: -
script: game_liars_dice
source: lib/ui/games/games/liars_dice/screen.dart (LiarsDiceScreen)
