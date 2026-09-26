title: Multiplayer mode
desc: Switches the games hub to local-Wi-Fi multiplayer: tapping a game opens its lobby instead of a solo game.
layer: ux
keywords: multiplayer, wifi, local, lan, host, join, together
kind: toggle
looks: "Multiplayer Mode / Host or join over local Wi-Fi" switch at the top of Games; solo-only games show a "Solo only" badge.
reach: text:Games > text:Multiplayer Mode
needs: -
action: With it on, a multiplayer-ready game opens its lobby; Solitaire stays single-player.
expect: The switch turns on and Solitaire shows "Solo only".
uses: -
script: games
source: lib/ui/games/games_screen.dart (GamesScreen)
