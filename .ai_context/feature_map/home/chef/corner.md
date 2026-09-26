title: Chef's Corner
desc: Suggests a dish from what is in the pantry, the season, cuisine mood, guests' allergens and dietary needs.
layer: ux
keywords: suggest, what to cook, dish ideas, season, cuisine, allergens, diet
kind: screen
looks: "Chef's Corner" tab: pantry count, what is in season, cuisine and mood chips, allergen and diet chips, Meal Planner and "Suggest a Dish".
reach: text:Chef > text:Chef's Corner
needs: -
action: Pick moods and restrictions, then Suggest a Dish; needs pantry items marked "In Pantry".
expect: "In season" and "Suggest a Dish" are shown.
uses: -
script: chef
source: lib/ui/chef/chef_screen.dart (ChefScreen)
