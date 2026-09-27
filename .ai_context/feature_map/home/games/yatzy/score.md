title: Score a category (Yatzy)
desc: Record this turn's dice in one category of the score card; each category is used once.
layer: ux
keywords: score, category, ones, full house, straight, yatzy, chance
kind: button
looks: Score-card rows (Ones … Sixes, 3 of a Kind, Full House, Straights, Yatzy!, Chance) show the points you would get after a roll.
reach: text:Games > text:Yatzy > text:Roll Dice > text:Chance
needs: -
action: Scores the dice in that category and passes the turn to the AI.
expect: Chance is filled in for You and the AI takes its turn.
uses: system/ai/game_ai
script: game_yatzy
source: lib/ui/games/games/yatzy/screen.dart (YatzyScreen)
