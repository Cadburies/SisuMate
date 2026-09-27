title: Yatzy
desc: The dice game against the computer: roll five dice up to three times a turn and score each of the 15 categories once. Also playable over local Wi-Fi.
layer: ux
keywords: yatzy, yahtzee, dice, score card, categories
kind: screen
looks: Five dice with "Rolls left", a Roll Dice button and a score card with Upper and Lower sections for You and AI.
reach: text:Games > text:Yatzy
needs: -
action: Roll, tap dice to hold them, roll again, then tap a category to score; the AI plays its turn automatically.
expect: "Tap Roll to start your turn!" with "Rolls left: 3".
uses: home/games/help
script: game_yatzy
source: lib/ui/games/games/yatzy/screen.dart (YatzyScreen); lib/ui/games/games/yatzy/gameflow.md
