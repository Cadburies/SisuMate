title: Add an inventory item
desc: Add something to the inventory: name, location, quantity and unit, serial number, barcode (scan or type), photo and linked maintenance task. Pro only.
layer: ux
keywords: add, new item, spare, part, barcode, scan, photo
kind: fab
looks: Round + button on Inventory; opens "Add Inventory Item".
reach: text:Inventory > tip:Add inventory item
needs: tier=pro (on Free it explains that editing needs Pro)
action: Save adds the item; "Scan barcode" uses the camera on a phone.
expect: "Add Inventory Item" opens; after Save the item shows with "Qty: 1".
uses: -
script: inventory
source: lib/ui/inventory/inventory_screen.dart (InventoryScreen)
