title: Uno
desc: The colour-and-number card game against the computer: match the top card's colour or number, use action cards, and empty your hand first. Also playable over local Wi-Fi.
layer: ux
keywords: uno, cards, colours, wild, draw four, card game
kind: screen
looks: The AI's card count on top, the discard pile and draw deck in the middle, your hand below with Play Card and Draw.
reach: text:Games > text:Uno
needs: -
action: Tap a matching card and Play Card, or Draw; after a Wild you choose a colour. The AI plays automatically.
expect: "Your turn! Play a card or draw." with 7 cards each.
uses: home/games/help
script: game_uno
source: lib/ui/games/games/uno/screen.dart (UnoScreen); lib/ui/games/games/uno/gameflow.md
