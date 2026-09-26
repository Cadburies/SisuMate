title: How to play
desc: The rules and a quick guide for each game, opened from the question-mark button inside the game.
layer: ux
keywords: rules, help, how to play, guide, instructions
kind: screen
looks: Question-mark button in each game's title bar; opens the game's rules with sections like "How a Turn Works".
reach: text:Games > text:Yatzy > tip:How to play
needs: -
action: Shows the rules for that game.
expect: Yatzy's rules with "How a Turn Works" are shown.
uses: -
script: games
source: lib/ui/games/components/game_help_screen.dart (GameHelpScreen, showGameHelp); lib/ui/games/components/game_rules_data.dart
