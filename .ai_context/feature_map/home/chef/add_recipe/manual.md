title: Write a recipe
desc: The recipe editor: name, photo, times, cooking method, cuisine and flavour tags, ingredients and method.
layer: ux
keywords: recipe editor, write, ingredients, tags, photo, method
kind: screen
looks: "Add Recipe" editor with Save, tag pickers, an ingredient list with + and a camera button.
reach: text:Chef > tip:Add recipe > text:Add manually
needs: tier=pro
action: Fill in the recipe and tap Save.
expect: The "Add Recipe" editor opens with "No ingredients yet — tap + to add".
uses: -
script: chef
source: lib/ui/cocktails/cocktails_screen.dart (AddEditRecipeDialog)
