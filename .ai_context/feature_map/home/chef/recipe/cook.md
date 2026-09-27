title: Cooking mode
desc: Step-by-step cooking view that shows one instruction at a time.
layer: ux
keywords: cook, cooking mode, steps, method, instructions, hands free
kind: screen
looks: "Step N of M" with the current instruction and Previous / Next buttons.
reach: text:Chef > text:Amarula Malva > text:Cook
needs: -
action: Next and Previous move through the method.
expect: "Step 1 of 2" is shown.
uses: -
script: chef
source: lib/ui/chef/chef_screen.dart (ChefRecipeDetailScreen); lib/ui/chef/chef_screen.dart (CookingModeScreen)
