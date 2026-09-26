title: Share inventory items
desc: Pick several inventory items and share them together.
layer: ux
keywords: share, select, multiple, send, export
kind: button
looks: Checklist button in the Inventory title bar; switches to "N selected" with Share and Cancel.
reach: text:Inventory > tip:Add inventory item > type:Name=Spare impeller > text:Save > tip:Select to share
needs: tier=pro
action: Tap items to select them, then Share selected.
expect: The title changes to "0 selected" with "Share selected" and "Cancel".
uses: -
script: inventory
source: lib/ui/inventory/inventory_screen.dart (InventoryScreen)
