title: Add a pantry ingredient
desc: Add your own pantry item with photo, expiry date, allergens and dietary tags. Pro only.
layer: ux
keywords: add ingredient, pantry item, custom, expiry, allergens
kind: fab
looks: Round + button on My Pantry; opens "Add Pantry Item".
reach: text:Chef > text:My Pantry > tip:Add custom ingredient
needs: tier=pro (on Free it explains that custom pantry ingredients need Pro)
action: Fill in the item and save it to the pantry.
expect: "Add Pantry Item" opens.
uses: -
script: chef
source: lib/ui/chef/chef_screen.dart (ChefScreen)
