title: Cribbage
desc: Two-player cribbage against the computer, first to 121, with discard, pegging and counting phases. Also playable over local Wi-Fi.
layer: ux
keywords: cribbage, cards, crib, pegging, 121, card game
kind: screen
looks: Score bar ("You ◆ 0 / 121" vs AI), a message line, and your six-card hand.
reach: text:Games > text:Cribbage
needs: -
action: Pick two cards for the crib, then play cards in pegging and see hands counted; the AI plays automatically.
expect: "Your Hand — select 2 to discard" with your six cards.
uses: home/games/help
script: game_cribbage
source: lib/ui/games/games/cribbage/screen.dart (CribbageScreen); lib/ui/games/games/cribbage/gameflow.md
