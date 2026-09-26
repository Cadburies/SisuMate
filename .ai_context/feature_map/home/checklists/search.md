title: Search checklists
desc: Type to find checklists by name or by the items inside them.
layer: ux
keywords: search, find, filter, checklist, item
kind: field
looks: "Search checklists..." field at the top of the Checklists screen.
reach: text:Checklists > type:Search checklists...=engine
needs: -
action: Filters the checklists and shows which item matched ("Matched: …").
expect: Checklists with engine items show "Matched: Final Engine Check" and similar.
uses: -
script: checklists
source: lib/ui/checklists/checklist_screen.dart (ChecklistScreen); lib/ui/components/main_list_tile.dart (MainListSearchBar)
