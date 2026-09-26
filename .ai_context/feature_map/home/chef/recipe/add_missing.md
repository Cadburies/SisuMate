title: Add missing ingredients to shopping
desc: Adds every ingredient this recipe needs that is not in your pantry to the shopping list, in whole packs for the chosen servings.
layer: ux
keywords: missing, shopping, buy ingredients, add to list, provisioning
kind: button
looks: "Add N missing to shopping" button under the ingredient estimates.
reach: text:Chef > text:Amarula Malva > text:Add 2 missing to shopping
needs: -
action: Adds the missing packs to Shopping and confirms how many lines were added.
expect: A message says "2 pack lines added to shopping".
uses: home/shopping
script: chef
source: lib/ui/chef/chef_screen.dart (ChefRecipeDetailScreen)
