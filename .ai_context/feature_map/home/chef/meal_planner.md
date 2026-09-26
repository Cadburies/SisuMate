title: Meal planner
desc: Plan breakfast, lunch, dinner and snacks for each day of a trip, then turn the plan into a provision list.
layer: ux
keywords: meal plan, menu plan, trip meals, days, provisioning
kind: screen
looks: "Meal Planner" list of plans; each shows its dates, guests and how many slots are planned.
reach: text:Chef > text:Chef's Corner > text:Meal Planner
needs: -
action: Tap a plan to fill its meal slots; + creates a plan.
expect: "No meal plans yet" on a fresh install.
uses: -
script: chef
source: lib/ui/chef/meal_planner_screen.dart
