title: New game (Yatzy)
desc: Starts a fresh game of Yatzy with an empty score card.
layer: ux
keywords: new game, restart, reset
kind: button
looks: Refresh button in the title bar.
reach: text:Games > text:Yatzy > tip:New game
needs: -
action: Clears both score cards.
expect: "Tap Roll to start your turn!" again.
uses: -
script: game_yatzy
source: lib/ui/games/games/yatzy/screen.dart (YatzyScreen)
