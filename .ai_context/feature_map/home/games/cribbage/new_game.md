title: New game (Cribbage)
desc: Starts a fresh game of Cribbage.
layer: ux
keywords: new game, restart, reset, deal
kind: button
looks: Refresh button in the title bar.
reach: text:Games > text:Cribbage > tip:New game
needs: -
action: Resets the scores and deals a new hand.
expect: "Your Hand — select 2 to discard" with a new hand.
uses: -
script: game_cribbage
source: lib/ui/games/games/cribbage/screen.dart (CribbageScreen)
