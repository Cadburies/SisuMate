title: Checkers
desc: Checkers (draughts) against the computer; you play red and move first. Also playable over local Wi-Fi.
layer: ux
keywords: checkers, draughts, board game, king, jump
kind: screen
looks: 8×8 board with red (you) and black (AI) pieces; a status line tells you what to do.
reach: text:Games > text:Checkers
needs: -
action: Tap one of your red pieces, then a highlighted square to move or jump; reaching the far row makes a king. The AI replies automatically.
expect: "Your turn — tap a red piece to select it."
uses: home/games/help
script: game_checkers
source: lib/ui/games/games/checkers/screen.dart (CheckersScreen); lib/ui/games/games/checkers/gameflow.md
