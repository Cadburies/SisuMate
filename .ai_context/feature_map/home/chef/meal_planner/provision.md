title: Provision list
desc: Totals every ingredient the plan needs, compares it with the pantry, and lists the shortfall to buy.
layer: ux
keywords: provision, provisioning, totals, shortfall, shopping list, email
kind: screen
looks: "Provision List" with Consolidated Provisions and Shopping shortfall sections; buttons to add the shortfall to shopping, email or copy.
reach: text:Chef > text:Chef's Corner > text:Meal Planner > tip:New meal plan > text:Create
needs: -
action: From a plan, the list button opens this; add the shortfall to Shopping, email it or copy it.
expect: "Consolidated Provisions" and "Shopping shortfall" are shown.
uses: home/shopping
script: chef
source: lib/ui/chef/provision_planner_screen.dart
