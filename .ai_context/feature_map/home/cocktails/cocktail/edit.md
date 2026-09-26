title: Edit a cocktail
desc: Change a cocktail recipe. Pro only.
layer: ux
keywords: edit, change, modify, recipe, cocktail
kind: fab
looks: Round pencil button on a cocktail page (Pro only).
reach: text:Cocktails > text:Mai Tai > tip:Edit cocktail
needs: tier=pro (the button is hidden on Free)
action: Opens the cocktail editor with the recipe filled in.
expect: The cocktail editor opens with Save.
uses: -
script: cocktails
source: lib/ui/cocktails/cocktails_screen.dart (CocktailRecipeDetailScreen, AddEditRecipeDialog)
