title: Play a card (Uno)
desc: Play a card that matches the top card's colour or number, or a Wild; choose a colour after a Wild.
layer: ux
keywords: play, card, match, wild, choose colour
kind: button
looks: Tap a card in your hand, then "Play Card"; a Wild opens "Choose a color".
reach: text:Games > text:Uno
needs: -
action: Plays the selected card if it's legal; action cards (Skip, Reverse, +2, Wild +4) take effect.
expect: The card lands on the discard pile and the AI takes its turn.
uses: system/ai/game_ai
script: game_uno
source: lib/ui/games/games/uno/screen.dart (UnoScreen)
