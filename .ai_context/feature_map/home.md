title: Home screen
desc: The main screen of Sisu Mate: a grid of module tiles, a passage readiness card and the menu.
layer: ux
keywords: home, start, main, tiles, modules, dashboard
kind: screen
looks: Grid of coloured module tiles under the Sisu Mate title bar, with the readiness card above it.
reach: -
needs: onboarding=seen
action: Tap a tile to open that module; press and hold a tile to rearrange them; the menu button opens settings and your account.
expect: The module tiles are shown, starting with "Shopping".
uses: -
script: home
source: lib/ui/home/home_screen.dart (HomeScreen)
