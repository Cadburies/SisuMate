title: Fold (Poker)
desc: Give up the hand; the AI takes the pot.
layer: ux
keywords: fold, give up, quit hand
kind: button
looks: "Fold" button in the betting row.
reach: text:Games > text:Poker > text:Fold
needs: -
action: Ends the hand and a new one is dealt.
expect: The AI's chips grow by the pot and "Pot: $0" shows.
uses: -
script: game_poker
source: lib/ui/games/games/poker/screen.dart (PokerScreen)
