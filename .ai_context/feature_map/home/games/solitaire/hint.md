title: Solitaire hint
desc: Suggests a good next move.
layer: ux
keywords: hint, help, next move, stuck
kind: button
looks: Light-bulb button in the title bar ("Hide hints" when on).
reach: text:Games > text:Solitaire > tip:Show hint
needs: -
action: Shows a suggested move, for example "Move 4♥ from column 2 to column 4."
expect: A hint line describing a move appears.
uses: system/ai/game_ai
script: game_solitaire
source: lib/ui/games/games/solitaire/screen.dart (SolitaireScreen)
