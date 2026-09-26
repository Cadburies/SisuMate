title: A recipe
desc: One recipe with servings, ingredients and quantities, allergens, cost and calorie estimates, method, and suggested drink pairings.
layer: ux
keywords: recipe, ingredients, servings, method, pairing, calories, cost
kind: screen
looks: Recipe page with prep and cook times, a Servings selector (2–12), the ingredient list, estimates, Instructions, Cook, Suggested Pairing and a leftovers button.
reach: text:Chef > text:Amarula Malva
needs: -
action: Change servings to rescale; add missing ingredients to shopping; start cooking mode; favourite or share it.
expect: "Ingredients", "Servings:" and "Suggested Pairing" are shown.
uses: -
script: chef
source: lib/ui/chef/chef_screen.dart (ChefRecipeDetailScreen)
