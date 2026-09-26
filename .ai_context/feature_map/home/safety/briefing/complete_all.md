title: Complete all briefing points
desc: Mark every point in a briefing as done in one go.
layer: ux
keywords: complete all, tick all, done, bulk
kind: menu
looks: "Complete All" in the briefing's menu.
reach: text:Safety > text:Day Trip Safety Briefing > tip:Menu > text:Complete All
needs: tier=pro
action: Confirm to mark every point done.
expect: A "Complete All" confirmation is shown.
uses: -
script: safety
source: lib/ui/safety/safety_briefing_screen.dart (SafetyBriefingItemsScreen)
