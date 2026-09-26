title: Add a recipe
desc: Add your own recipe, typed in or imported from a web page. Pro only.
layer: ux
keywords: add recipe, new recipe, import url, write recipe
kind: fab
looks: Round + button on the Chef recipe list; opens a sheet with Add manually and Import from URL.
reach: text:Chef > tip:Add recipe
needs: tier=pro (on Free it explains that editing needs Pro)
action: Choose how to add the recipe.
expect: "Add manually" and "Import from URL" are offered.
uses: -
script: chef
source: lib/ui/chef/chef_screen.dart (_showAddRecipeOptions)
