title: Title bar and status line
desc: The bar at the top of every screen: back, the screen name, a status line with boat, plan and connection, and the menu button.
layer: ux
keywords: title bar, status, back, menu, boat name, online, offline, pro, free, syncing
kind: banner
looks: Screen name with a small line underneath like "My Boat • Pro • Online", a back arrow on the left and a menu button on the right.
reach: text:Shopping
needs: -
action: Back returns to the previous screen; Menu opens that screen's menu. The status line shows the active boat ("No Boat" if none), Free or Pro, Online or Offline, and "Syncing (N)" while uploads are waiting.
expect: The status line reads "No Boat • Pro • Online" on a fresh install with Pro.
uses: -
script: shared_chrome
source: lib/ui/components/title_tile.dart (TitleTile)
