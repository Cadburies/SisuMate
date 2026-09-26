title: New meal plan
desc: Create a plan for a trip: start date, number of days, guests and their profiles.
layer: ux
keywords: new plan, trip, days, guests, create
kind: fab
looks: Round + button on the Meal Planner; opens "New Meal Plan".
reach: text:Chef > text:Chef's Corner > text:Meal Planner > tip:New meal plan
needs: -
action: Create adds a plan named after its start week.
expect: "New Meal Plan" opens; after Create a plan like "Week of <date>" is listed.
uses: -
script: chef
source: lib/ui/chef/meal_planner_screen.dart
