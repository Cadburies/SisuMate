title: Inventory reorder
desc: Works out which inventory spares are low and how many to reorder.
layer: logic
keywords: reorder, low stock, spares, inventory
kind: service
looks: -
reach: inventory and suggestions
needs: -
action: Compares quantity against minimums and proposes reorder lines.
expect: Low items produce reorder lines.
uses: -
script: test/inventory_reorder_service_test.dart
source: lib/services/inventory_reorder_service.dart (InventoryReorderService, InventoryReorderLine)
