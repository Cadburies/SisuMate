title: Safety briefings
desc: Crew safety briefings (day trip and long passage) that you walk through point by point before sailing.
layer: ux
keywords: safety, briefing, crew briefing, emergency, lifejacket, day trip, passage
kind: screen
looks: "Safety Briefings" screen with a card per briefing.
reach: text:Safety
needs: -
action: Tap a briefing to open its points.
expect: "Day Trip Safety Briefing" and "Long Passage Safety Briefing" are listed.
uses: -
script: safety
source: lib/ui/safety/safety_screen.dart (SafetyScreen)
