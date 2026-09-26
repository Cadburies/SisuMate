title: Edit an item
desc: Change an item's title and details from its full page.
layer: ux
keywords: edit, change, rename, modify, item page
kind: button
looks: "Edit" button on the item page; in edit mode it shows Cancel and Save.
reach: text:Checklists > text:Last Minute Departure Checks > text:Final Weather Check > text:Edit
needs: -
action: Switches the page into edit mode.
expect: Cancel and Save buttons are shown.
uses: -
script: shared_components
source: lib/ui/components/item_detail_shell.dart (ItemDetailShell)
