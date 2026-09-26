title: Solitaire
desc: Klondike solitaire for one player, with hints and a move counter.
layer: ux
keywords: solitaire, klondike, patience, cards, single player
kind: screen
looks: Stock and waste piles, four foundations (♣ ♦ ♥ ♠) and seven tableau columns; a move counter in the title bar.
reach: text:Games > text:Solitaire
needs: -
action: Tap the stock to draw, tap a card to move it to a legal place; build each suit up to the foundations.
expect: The stock shows 24 cards and the move counter reads 0mv.
uses: home/games/help
script: game_solitaire
source: lib/ui/games/games/solitaire/screen.dart (SolitaireScreen); lib/ui/games/games/solitaire/gameflow.md
