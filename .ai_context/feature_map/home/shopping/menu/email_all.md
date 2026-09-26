title: Email all shopping lists
desc: Sends every shopping section in one email from your phone's mail app.
layer: ux
keywords: email, send, share, list, mail
kind: menu
looks: "Email All Lists" in the Shopping menu.
reach: text:Shopping > tip:Menu > text:Email All Lists
needs: platform=device
action: Opens your mail app with the whole list written out.
expect: The mail composer opens with the shopping list.
uses: -
script: -
source: lib/ui/shopping/shopping_screen.dart (ShoppingScreen); lib/services/email_service.dart
