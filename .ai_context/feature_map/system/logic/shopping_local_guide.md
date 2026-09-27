title: Item shop guide
desc: Offline advice for buying one item: which kinds of shop to try and any compliance flag.
layer: logic
keywords: shop guide, where to buy, offline, item
kind: service
looks: -
reach: Shopping row sparkle badge
needs: -
action: Builds the guide from the item's origin and the compliance pack.
expect: The guide lists shop types and "No red-flag keyword matched" when clean.
uses: system/ai/compliance_pack
script: test/shopping_item_local_guide_test.dart
source: lib/services/shopping_item_local_guide.dart (ShoppingItemLocalGuide)
