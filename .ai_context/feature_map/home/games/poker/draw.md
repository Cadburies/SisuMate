title: Discard and draw (Poker)
desc: After betting, tap the cards you want to throw away and draw replacements.
layer: ux
keywords: draw, discard, replace cards, poker
kind: button
looks: "Tap cards to discard", then a "Draw (N discarded)" button.
reach: text:Games > text:Poker > text:Check
needs: -
action: Selected cards are replaced; then hands are shown down.
expect: The draw button shows how many cards you are discarding.
uses: -
script: game_poker
source: lib/ui/games/games/poker/screen.dart (PokerScreen)
