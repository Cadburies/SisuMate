title: Ingredient page
desc: Full page for a pantry or bar ingredient: stock state, pack size, price, allergens and the menus that use it.
layer: ux
keywords: ingredient, pantry, bar, detail, allergens, price, stock, menus
kind: screen
looks: Ingredient name, "My Pantry · N of M", stock status, allergens, "Used in menus", with In stock / Shopping / Edit buttons.
reach: text:Chef > text:My Pantry > text:Aged Balsamic Vinegar
needs: -
action: Shows the ingredient; swipe sideways for the next one.
expect: "My Pantry · 1 of 243" is shown.
uses: -
script: shared_components
source: lib/ui/components/ingredient_detail_screen.dart (IngredientDetailScreen)
