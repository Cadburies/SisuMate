title: Dudo
desc: The Chilean dice-bluffing game: bid on how many dice of a face are under all the cups, call "Dudo!" when you think a bid is wrong. 2–6 players, human or computer, also over local Wi-Fi.
layer: ux
keywords: dudo, perudo, liar's dice, dice, bluff, cups
kind: screen
looks: Setup screen "Add Players (2–6)" with Add AI Player, Add Human Player and Start Game.
reach: text:Games > text:Dudo
needs: -
action: Add yourself and at least one AI, then Start Game.
expect: "Add Players (2–6)" with the three buttons.
uses: home/games/help
script: game_dudo
source: lib/ui/games/games/dudo/screen.dart (DudoScreen); lib/ui/games/games/dudo/gameflow.md
