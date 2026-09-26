title: Coach mode (Backgammon)
desc: Turns on hints: a Hint button suggests a good move each turn.
layer: ux
keywords: coach, hint, help, learn, suggestion
kind: toggle
looks: Coach button in the title bar; when on, a "Hint" button appears.
reach: text:Games > text:Backgammon > tip:Coach mode
needs: -
action: Toggles coach mode; tap Hint on your turn for a suggested move.
expect: The "Hint" button appears and the button reads "Coach on (tap Hint)".
uses: system/ai/game_ai
script: game_backgammon
source: lib/ui/games/games/backgammon/screen.dart (BackgammonScreen)
