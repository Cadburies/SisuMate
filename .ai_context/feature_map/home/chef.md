title: Chef
desc: The galley: recipes and menus, your pantry, dish suggestions, meal planning and provisioning.
layer: ux
keywords: chef, galley, recipes, menus, cooking, food, pantry, meals
kind: screen
looks: Recipe cards with cuisine and flavour chips, sort and filter chips on top, tabs for My Pantry and Chef's Corner, and a + button.
reach: text:Chef
needs: -
action: Tap a recipe to open it; switch tabs for the pantry and suggestions; + adds a recipe.
expect: Recipes such as "Amarula Malva" are listed.
uses: -
script: chef
source: lib/ui/chef/chef_screen.dart (ChefScreen)
