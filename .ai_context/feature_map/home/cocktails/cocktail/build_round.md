title: Build a round
desc: Scales a cocktail to a batch for several people, with total ingredient amounts and garnishes.
layer: ux
keywords: batch, round, party, group, scale, pitcher
kind: screen
looks: "Build a Round" button on a cocktail; opens a batch page with a Drinks count and "Total batch" ingredients.
reach: text:Cocktails > text:Mai Tai > text:Build a Round
needs: -
action: Change the number of drinks and read the total amounts.
expect: "Drinks:" and "Total batch" are shown.
uses: -
script: cocktails
source: lib/ui/cocktails/cocktails_screen.dart (CocktailRecipeDetailScreen); lib/ui/cocktails/cocktails_screen.dart (CocktailBatchScreen)
