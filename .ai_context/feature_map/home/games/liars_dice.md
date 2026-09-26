title: Liar's Dice
desc: The poker-dice bluffing game: roll five dice, declare a hand (true or not), and the next player accepts or challenges. 2–10 players, also over local Wi-Fi.
layer: ux
keywords: liar's dice, poker dice, bluff, declare, challenge, dice game
kind: screen
looks: Setup screen "Add Players (2–10)" with Add AI Player, Add Human Player and Start Game.
reach: text:Games > text:Liar's Dice
needs: -
action: Add yourself and at least one AI, then Start Game.
expect: "Add Players (2–10)" with the three buttons.
uses: home/games/help
script: game_liars_dice
source: lib/ui/games/games/liars_dice/screen.dart (LiarsDiceScreen); lib/ui/games/games/liars_dice/gameflow.md
