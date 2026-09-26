title: Start a Liar's Dice game
desc: Starts the first round; ties for first player re-roll.
layer: ux
keywords: start, begin, play
kind: button
looks: "Start Game" on the setup screen.
reach: text:Games > text:Liar's Dice > text:Add Human Player > text:Add AI Player > text:Start Game
needs: -
action: Starts play; the scoreboard shows each player's counters.
expect: The setup screen closes and the "Scoreboard" appears.
uses: -
script: game_liars_dice
source: lib/ui/games/games/liars_dice/screen.dart (LiarsDiceScreen)
