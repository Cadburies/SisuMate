title: Provisioning and nutrition
desc: Totals a meal plan's ingredients by servings and days, compares with the pantry, and estimates calories and allergens per recipe.
layer: logic
keywords: provision, totals, calories, allergens, meal plan
kind: service
looks: -
reach: Meal planner → Provision list; recipe estimates
needs: -
action: Scales and consolidates ingredients, subtracts pantry stock, computes shortfall; calorie and allergen summaries per recipe.
expect: The provision list shows totals and the shortfall to buy.
uses: -
script: test/provision_calculator_test.dart
source: lib/services/provision_calculator.dart (ProvisionCalculator, ProvisionResult); lib/services/calorie_calculator.dart (CalorieCalculator); lib/services/recipe_allergen_service.dart (RecipeAllergenService)
