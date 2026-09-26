title: Leftover ideas
desc: Suggests dishes you can make from what is marked in your pantry.
layer: ux
keywords: leftovers, ideas, what to cook, use up, pantry
kind: sheet
looks: "Got Leftovers? Get Ideas" button at the bottom of a recipe; opens "Leftover Ideas".
reach: text:Chef > text:Amarula Malva > text:Got Leftovers? Get Ideas
needs: -
action: Lists matching dishes from pantry stock; needs some ingredients marked as in the pantry.
expect: "Leftover Ideas" opens (it asks you to mark pantry items first on a fresh install).
uses: -
script: chef
source: lib/ui/chef/chef_screen.dart (ChefRecipeDetailScreen)
