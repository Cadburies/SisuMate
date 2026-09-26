title: Plan a port run
desc: Plans a shopping trip ashore: what to buy, which kinds of shop, and local tips, working offline with live shop names optional.
layer: ux
keywords: port run, shopping trip, ashore, marina, town, shops, plan
kind: dialog
looks: Map-pin button in the Shopping title bar; opens "Port run · N to buy".
reach: text:Shopping > tip:Plan port run
needs: -
action: Groups the to-buy list by shop type; set the port or allow location to name real shops; Copy shares the plan.
expect: "Port run · 0 to buy" with Copy and Close is shown on an empty list.
uses: system/logic/port_run
script: shopping
source: lib/ui/shopping/shopping_port_run_dialog.dart
