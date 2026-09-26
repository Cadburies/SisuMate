title: New game (Poker)
desc: Resets the chips and deals a new hand.
layer: ux
keywords: new game, restart, reset, deal
kind: button
looks: Refresh button in the title bar.
reach: text:Games > text:Poker > tip:New game
needs: -
action: Resets to $500 each and deals.
expect: "Ante: $10 each. Bet, check, or fold?" again.
uses: -
script: game_poker
source: lib/ui/games/games/poker/screen.dart (PokerScreen)
