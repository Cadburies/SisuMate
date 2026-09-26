title: My Pantry
desc: Every galley ingredient with what is aboard, pack size, price, allergens and the menus that use it.
layer: ux
keywords: pantry, ingredients, stock, galley, food stores, provisions
kind: screen
looks: "My Pantry" tab: ingredient rows with allergen and flavour chips, pack size and price.
reach: text:Chef > text:My Pantry
needs: -
action: Tap an ingredient for its page; swipe right for Shopping, left for In stock.
expect: Ingredients such as "Aged Balsamic Vinegar" are listed.
uses: shared/ingredient_detail, shared/swipe/add_to_shopping, shared/swipe/in_stock
script: chef
source: lib/ui/chef/chef_screen.dart (ChefScreen)
