title: Share crew details
desc: Pick several crew members and share their details together, for example for a crew list at clearance.
layer: ux
keywords: share, crew list, select, clearance, send
kind: button
looks: Checklist button in the Crew title bar; switches to "N selected" with Share and Cancel.
reach: text:Crew & Contacts > tip:Add crew member > type:Name=Anna Smith > text:Save > tip:Select to share
needs: tier=pro
action: Tap people to select them, then Share selected.
expect: The title changes to "0 selected".
uses: -
script: crew
source: lib/ui/crew/crew_screen.dart (CrewScreen)
