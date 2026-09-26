title: Rearrange Home tiles
desc: Press and hold any Home tile to make the tiles wiggle, then drag them into your own order.
layer: ux
keywords: reorder, rearrange, move tiles, customise, layout, drag, jiggle, order
kind: longpress
looks: Tiles wiggle and a "Done" button appears in the title bar.
reach: long:Shopping
needs: -
action: Drag a tile onto another position; the order is saved on this device only. Tap Done to finish.
expect: The tiles wiggle and "Done" is shown; tapping a tile does not open it until you tap Done.
uses: -
script: home
source: lib/ui/home/home_screen.dart (HomeScreen); lib/ui/home/components/home_module_tile.dart; lib/ui/home/home_modules.dart (HomeModules)
