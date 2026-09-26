title: Safety briefing filters
desc: Choose whether finished, unfinished and hidden briefing points are shown.
layer: ux
keywords: filter, show completed, show incomplete, hidden, menu
kind: drawer
looks: Menu on the Safety Briefings screen with Show Completed, Show Incomplete and Show Hidden switches.
reach: text:Safety > tip:Menu
needs: -
action: Toggle which briefings and points are shown.
expect: "Show Completed Items" and "Show Hidden Items" are shown.
uses: home/drawer
script: safety
source: lib/ui/safety/safety_screen.dart (SafetyScreen)
