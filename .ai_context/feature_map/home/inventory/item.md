title: An inventory item
desc: One inventory item in full, with the maintenance task it is used by, and Edit and Delete.
layer: ux
keywords: item, detail, spare, used by, edit, delete
kind: screen
looks: Item page with "N of M", Name, Quantity, "Used by", Delete, Edit and a photo button.
reach: text:Inventory > tip:Add inventory item > type:Name=Spare impeller > text:Save > text:Spare impeller
needs: tier=pro
action: Edit or delete the item; swipe sideways for the next one.
expect: "1 of 1" and "Used by" are shown.
uses: shared/record_detail
script: inventory
source: lib/ui/inventory/inventory_screen.dart (InventoryScreen); lib/ui/components/record_detail_screen.dart (RecordDetailScreen)
