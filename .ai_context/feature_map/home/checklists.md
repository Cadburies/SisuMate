title: Checklists
desc: All your checklists (departure, watch, annual and your own), each with its progress.
layer: ux
keywords: checklists, checks, lists, departure, watch, annual, routine
kind: screen
looks: Grid of checklist cards showing "N / M items done" and "N remaining", a search bar on top and a + button.
reach: text:Checklists
needs: -
action: Tap a checklist to open its items.
expect: The seeded checklists such as "Last Minute Departure Checks" are listed.
uses: -
script: checklists
source: lib/ui/checklists/checklist_screen.dart (ChecklistScreen)
