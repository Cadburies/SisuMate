title: Check (Poker)
desc: Pass the betting to the AI without adding chips.
layer: ux
keywords: check, pass, poker
kind: button
looks: "Check" button in the betting row.
reach: text:Games > text:Poker > text:Check
needs: -
action: The AI then bets or checks; you may have to call or fold.
expect: The AI responds; the pot and chip counts update.
uses: system/ai/game_ai
script: game_poker
source: lib/ui/games/games/poker/screen.dart (PokerScreen)
