title: Synchronise recipe counts
desc: Recounts which recipes and drinks you can make from what is marked in stock.
layer: ux
keywords: synchronise, sync, recount, recipes, ingredients, counts, refresh
kind: menu
looks: "Synchronise" row under Data Management in the menu.
reach: tip:Menu > text:Synchronise
needs: -
action: Recalculates the missing-ingredient counts for every recipe and cocktail.
expect: A message says "Recipe counts updated".
uses: -
script: home
source: lib/ui/components/common_drawer.dart (_handleSync)
