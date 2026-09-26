title: Draw a card (Uno)
desc: Take a card from the deck when you can't or don't want to play.
layer: ux
keywords: draw, pick up, deck, pass
kind: button
looks: "Draw" button under your hand.
reach: text:Games > text:Uno > text:Draw
needs: -
action: Adds a card to your hand and passes the turn to the AI.
expect: "Drew <card>. Opponent's turn." and your hand has 8 cards.
uses: -
script: game_uno
source: lib/ui/games/games/uno/screen.dart (UnoScreen)
