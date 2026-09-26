title: Reset the game (Dudo)
desc: Clears the table and returns to setup.
layer: ux
keywords: reset, new game, restart
kind: button
looks: Reset button in the title bar.
reach: text:Games > text:Dudo > tip:Reset game
needs: -
action: Returns to "Add Players".
expect: "Add Players (2–6)" is shown.
uses: -
script: game_dudo
source: lib/ui/games/games/dudo/screen.dart (DudoScreen)
