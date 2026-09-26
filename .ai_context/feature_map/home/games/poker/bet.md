title: Bet (Poker)
desc: Bet $20 into the pot.
layer: ux
keywords: bet, raise, chips, poker
kind: button
looks: "Bet $20" button in the betting row.
reach: text:Games > text:Poker > text:Bet $20
needs: -
action: Adds $20 to the pot; the AI calls, raises or folds.
expect: Your chips drop by $20 and the pot grows.
uses: system/ai/game_ai
script: game_poker
source: lib/ui/games/games/poker/screen.dart (PokerScreen)
