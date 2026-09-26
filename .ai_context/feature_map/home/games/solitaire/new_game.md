title: New game (Solitaire)
desc: Deals a fresh game of Solitaire.
layer: ux
keywords: new game, redeal, restart
kind: button
looks: Refresh button in the title bar (and "New Game" on the win screen).
reach: text:Games > text:Solitaire > tip:New game
needs: -
action: Shuffles and deals.
expect: The stock shows 24 cards and the counter reads 0mv.
uses: -
script: game_solitaire
source: lib/ui/games/games/solitaire/screen.dart (SolitaireScreen)
