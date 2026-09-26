title: Inventory
desc: Everything aboard worth tracking (spares, tools, safety gear), with quantity, location, serial and barcode.
layer: ux
keywords: inventory, spares, stock, parts, equipment, onboard, stores
kind: screen
looks: "Inventory" list with quantities; select, import/export and + buttons.
reach: text:Inventory
needs: -
action: Tap an item to see it; + adds one; the select button lets you share several.
expect: "No inventory items yet" on a fresh install.
uses: -
script: inventory
source: lib/ui/inventory/inventory_screen.dart (InventoryScreen)
