title: Add a briefing point
desc: Add your own point to a safety briefing. Pro only.
layer: ux
keywords: add, new point, custom, briefing item
kind: fab
looks: Round + button on a briefing ("Upgrade to Pro" on Free).
reach: text:Safety > text:Day Trip Safety Briefing > tip:Add safety item
needs: tier=pro (on Free the button reads "Upgrade to Pro")
action: Opens the add-item dialog for this briefing.
expect: The add-item dialog opens.
uses: shared/dialogs/add_checklist_item
script: safety
source: lib/ui/safety/safety_briefing_screen.dart (SafetyBriefingItemsScreen)
