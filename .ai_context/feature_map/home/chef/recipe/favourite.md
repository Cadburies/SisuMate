title: Favourite a recipe
desc: Mark a recipe as a favourite so the Favourites filter shows it.
layer: ux
keywords: favourite, favorite, star, heart, save
kind: button
looks: Heart button in the recipe's title bar.
reach: text:Chef > text:Amarula Malva > tip:Favourite
needs: -
action: Toggles the recipe in and out of Favourites.
expect: The recipe shows under the Favourites filter.
uses: -
script: chef
source: lib/ui/chef/chef_screen.dart (ChefRecipeDetailScreen)
