title: Start a Dudo game
desc: Rolls for who goes first and starts the round.
layer: ux
keywords: start, begin, play, roll
kind: button
looks: "Start Game" on the setup screen.
reach: text:Games > text:Dudo > text:Add Human Player > text:Add AI Player > text:Start Game
needs: -
action: Rolls to decide the first player, then deals dice under the cups.
expect: "Rolling to determine first player…", then either your bidding controls or "Waiting for AI…".
uses: -
script: game_dudo
source: lib/ui/games/games/dudo/screen.dart (DudoScreen)
