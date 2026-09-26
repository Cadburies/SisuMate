title: Backgammon
desc: Backgammon against the computer (you are white), with doubling, coach hints and a practice review; also playable over local Wi-Fi.
layer: ux
keywords: backgammon, board game, dice, doubling cube, tavla
kind: screen
looks: Board with your pieces (white) and the AI's (black), borne-off and bar counts, the doubling cube, and Roll Dice / Double ×2 buttons.
reach: text:Games > text:Backgammon
needs: -
action: Roll, then tap a piece and a destination to move; the AI plays its turn automatically. Rules: How to play.
expect: "Tap \"Roll\" to start your turn." with Roll Dice and Double ×2.
uses: home/games/help
script: game_backgammon
source: lib/ui/games/games/backgammon/screen.dart (BackgammonScreen); lib/ui/games/games/backgammon/gameflow.md
