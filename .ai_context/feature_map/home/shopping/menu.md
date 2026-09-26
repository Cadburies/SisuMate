title: Shopping menu
desc: Shopping options: show hidden items, email all lists, complete the shopping run, plus the shared main menu.
layer: ux
keywords: menu, options, hidden, email, complete run
kind: drawer
looks: Menu from the Shopping title bar titled "Filters & Options".
reach: text:Shopping > tip:Menu
needs: -
action: Opens the Shopping menu.
expect: "Show Hidden Items", "Email All Lists" and "Complete shopping run" are shown.
uses: home/drawer
script: shopping
source: lib/ui/shopping/shopping_screen.dart (ShoppingScreen)
