title: Complete from the item page
desc: Marks the item done from its full page. Free users get a few free edits before Pro is needed.
layer: ux
keywords: complete, done, uncomplete, item page, free edits
kind: button
looks: "Complete" button on the item page ("Uncomplete" once done).
reach: text:Checklists > text:Last Minute Departure Checks > text:Final Weather Check > text:Complete
needs: tier=free_limited (Free shows "Free preview: N edit(s) left"; Pro is unlimited)
action: Toggles the item done and records when it was completed.
expect: Status reads "completed" and a "Completed" date appears.
uses: -
script: shared_components
source: lib/ui/checklists/check_page_viewer.dart (CheckPageViewer); lib/services/free_edit_gate.dart
