title: Draw from the stock
desc: Turns one card from the stock onto the waste pile; when the stock is empty, the waste is recycled.
layer: ux
keywords: draw, stock, deck, turn card
kind: button
looks: The stock pile (top left) with its card count.
reach: text:Games > text:Solitaire > text:24
needs: -
action: Draws one card to the waste.
expect: The stock count drops to 23.
uses: -
script: game_solitaire
source: lib/ui/games/games/solitaire/screen.dart (SolitaireScreen)
