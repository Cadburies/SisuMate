title: Practice mode (Backgammon)
desc: After each of your turns, reviews your move against the best one.
layer: ux
keywords: practice, review, learn, analysis
kind: toggle
looks: Practice button in the title bar.
reach: text:Games > text:Backgammon > tip:Practice mode
needs: -
action: Toggles practice review after your turns.
expect: The button reads "Practice on (review after your turn)".
uses: system/ai/game_ai
script: game_backgammon
source: lib/ui/games/games/backgammon/screen.dart (BackgammonScreen)
