title: First launch
desc: What happens when Sisu Mate opens: a splash while your data loads, then the welcome tour the first time, or Home after that.
layer: ux
keywords: start, launch, open, splash, first run, loading
kind: screen
looks: Sisu Mate splash screen while the database opens and the bundled content loads.
reach: -
needs: platform=device
action: Opens the local database, loads bundled checklists and recipes on first run, restores theme and units, then shows the welcome tour or Home.
expect: The welcome tour on first launch; Home on every later launch.
uses: system/db/startup_init
script: test/startup_lifecycle_test.dart
source: lib/ui/startup/startup_screen.dart (StartupScreen, _goHome)
