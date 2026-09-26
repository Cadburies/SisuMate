title: Poker
desc: Five-card draw poker against the computer with chips, an ante, one betting round, a draw and a showdown. Also playable over local Wi-Fi.
layer: ux
keywords: poker, cards, five card draw, chips, bet, bluff
kind: screen
looks: "5-Card Draw Poker" table with both chip counts, the pot, the AI's face-down hand, your five cards, and Check / Bet $20 / Fold.
reach: text:Games > text:Poker
needs: -
action: Bet or check, then discard and draw, then compare hands; the AI acts automatically.
expect: "Ante: $10 each. Bet, check, or fold?" with Check, Bet $20 and Fold.
uses: home/games/help
script: game_poker
source: lib/ui/games/games/poker/screen.dart (PokerScreen); lib/ui/games/games/poker/gameflow.md
