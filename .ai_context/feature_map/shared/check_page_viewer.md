title: Checklist item page
desc: Full-page view of one checklist, safety or maintenance item, with page-through to the others in its list.
layer: ux
keywords: item, detail, page, view, check, step, instructions
kind: screen
looks: Item title, "<list> · N of M" position, status, Complete / Hide / Edit buttons and a photo.
reach: text:Checklists > text:Last Minute Departure Checks > text:Final Weather Check
needs: -
action: Shows the whole item; swipe sideways for the previous or next item in the list.
expect: "Last Minute Departure Checks · 2 of 17" is shown with the item's status.
uses: -
script: shared_components
source: lib/ui/checklists/check_page_viewer.dart (CheckPageViewer); lib/ui/components/item_detail_shell.dart (ItemDetailShell)
