title: Bid, call Dudo or Spot On
desc: On your turn, raise the bid, call "Dudo!" if you think the last bid is too high, or "Spot On" if you think it is exact.
layer: ux
keywords: bid, raise, dudo, call, spot on, calza, bluff
kind: button
looks: Your turn shows "You, make your bid." with quantity and face pickers and Bid (or Raise), Dudo! and Spot On buttons.
reach: text:Games > text:Dudo > text:Add Human Player > text:Add AI Player > text:Start Game
needs: -
action: Choose quantity and face then Bid/Raise; or challenge with Dudo! / Spot On to reveal the dice.
expect: After your action the next player moves; a challenge shows "Actual count" for the bid.
uses: system/ai/game_ai
script: game_dudo
source: lib/ui/games/games/dudo/screen.dart (DudoScreen)
