title: Checklist filters
desc: Choose whether finished and unfinished checklists are shown.
layer: ux
keywords: filter, show completed, show incomplete, hide done, menu
kind: drawer
looks: Menu on the Checklists screen with "Show Completed Items" and "Show Incomplete Items" switches.
reach: text:Checklists > tip:Menu
needs: -
action: Toggle which checklists are listed; the rest of the menu is the shared main menu.
expect: "Show Completed Items" and "Show Incomplete Items" are shown.
uses: home/drawer
script: checklists
source: lib/ui/checklists/checklist_screen.dart (ChecklistScreen)
