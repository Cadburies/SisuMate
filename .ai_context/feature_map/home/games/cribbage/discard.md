title: Discard to the crib
desc: Choose two of your six cards for the crib, then confirm.
layer: ux
keywords: discard, crib, choose cards, confirm
kind: button
looks: Tap two cards in your hand (they highlight); the button changes from "Select 2 more" to "Confirm Discard".
reach: text:Games > text:Cribbage
needs: -
action: After Confirm Discard the game moves on to pegging once the AI has discarded.
expect: The button reads "Confirm Discard" with two cards selected; after confirming, pegging starts.
uses: -
script: game_cribbage
source: lib/ui/games/games/cribbage/screen.dart (CribbageScreen)
