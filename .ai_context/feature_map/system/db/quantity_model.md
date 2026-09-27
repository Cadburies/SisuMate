title: Quantities and packs
desc: Converts recipe amounts into purchasable packs (e.g. 18 g butter → 1 × 250 g pack), scaled by servings, for shopping and provisioning.
layer: db
keywords: quantity, packs, units, servings, scale, purchase size
kind: service
looks: -
reach: recipe servings changes, add-missing-to-shopping, provision lists
needs: -
action: Parses purchase-size labels and rounds needed amounts up to whole packs.
expect: Pack counts and unit labels match the pantry item's purchase size.
uses: -
script: test/quantity_model_test.dart
source: lib/services/quantity_model.dart (QuantityModel, ShopPackLine, PurchaseSpec)
