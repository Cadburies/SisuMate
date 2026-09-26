title: Add a cocktail
desc: Write your own cocktail with photo, tags, flavours, ingredients and method. Pro only.
layer: ux
keywords: add cocktail, new drink, custom recipe
kind: fab
looks: Round + button on the Cocktails list; opens "Add Cocktail".
reach: text:Cocktails > tip:Add cocktail
needs: tier=pro (on Free it explains that editing needs Pro)
action: Fill in the recipe and tap Save.
expect: "Add Cocktail" opens.
uses: -
script: cocktails
source: lib/ui/cocktails/cocktails_screen.dart (AddEditRecipeDialog)
