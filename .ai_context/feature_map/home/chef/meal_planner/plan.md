title: A meal plan
desc: Day-by-day meal slots for one plan; assign a recipe to each slot.
layer: ux
keywords: plan, days, breakfast, lunch, dinner, snack, slots
kind: screen
looks: One section per day with Breakfast, Lunch, Dinner and Snack slots ("— none —" when empty), and a Provision list button.
reach: text:Chef > text:Chef's Corner > text:Meal Planner > tip:New meal plan > text:Create
needs: -
action: Open the plan from the list (it is named "Week of <start date>") and tap a slot to pick a recipe.
expect: The plan shows each day with its meal slots.
uses: -
script: chef
source: lib/ui/chef/meal_planner_screen.dart
