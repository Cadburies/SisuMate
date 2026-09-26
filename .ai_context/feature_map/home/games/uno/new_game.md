title: New game (Uno)
desc: Deals a fresh game of Uno.
layer: ux
keywords: new game, redeal, restart
kind: button
looks: Refresh button in the title bar ("Play Again" at the end of a game).
reach: text:Games > text:Uno > tip:New game
needs: -
action: Shuffles and deals 7 cards each.
expect: "Your turn! Play a card or draw." again.
uses: -
script: game_uno
source: lib/ui/games/games/uno/screen.dart (UnoScreen)
