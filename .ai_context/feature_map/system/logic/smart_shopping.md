title: Smart shopping ranking
desc: Orders the shopping list by what matters most (boat-critical spares, then what menus need).
layer: logic
keywords: priority, ranking, needed first, critical
kind: service
looks: -
reach: Shopping sort (Needed First, Sort by priority)
needs: -
action: Ranks items by criticality and upcoming need.
expect: Boat-critical spares come first.
uses: -
script: test/smart_shopping_service_test.dart
source: lib/services/smart_shopping_service.dart (SmartShoppingService, RankedShoppingItem)
