title: Port run planning
desc: Splits the to-buy list across kinds of shops ashore with local tips, offline; live shop names optional.
layer: logic
keywords: port run, shops, ashore, plan, shopping trip
kind: service
looks: -
reach: Shopping → Plan port run
needs: -
action: Groups items by shop type and produces a copyable plan.
expect: An empty list gives "0 to buy"; items are grouped by shop.
uses: -
script: test/shopping_port_run_test.dart
source: lib/services/shopping_port_run.dart (ShoppingPortRun, PortRunSheet)
