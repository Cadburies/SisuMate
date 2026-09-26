title: Run before you go
desc: A banner on Checklists that suggests which checklist to run next, based on your trip dates and the weather.
layer: ux
keywords: autopilot, suggestion, before you go, trip, departure, next checklist
kind: card
looks: "Run before you go" card above the checklists, one row per suggested checklist with the reason.
reach: text:Checklists
needs: -
action: Appears only when a trip is coming up; tap a row to open that checklist.
expect: The card lists the suggested checklists with why each is due.
uses: system/logic/checklist_autopilot
script: checklists
source: lib/ui/checklists/checklist_screen.dart (_ChecklistAutopilotBanner); lib/providers/checklist_autopilot_provider.dart
