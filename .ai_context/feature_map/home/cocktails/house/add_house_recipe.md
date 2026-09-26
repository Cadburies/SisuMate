title: Add a house recipe
desc: Write your own syrup or pre-mix. Pro only.
layer: ux
keywords: add syrup, house recipe, premix, homemade
kind: fab
looks: Round + button on the House tab; opens "Add House Recipe".
reach: text:Cocktails > text:House > wait:Honey Syrup > tip:Add house recipe
needs: tier=pro (on Free it explains that custom house recipes need Pro)
action: Fill in the recipe and tap Save.
expect: "Add House Recipe" opens.
uses: -
script: cocktails
source: lib/ui/cocktails/cocktails_screen.dart (_SyrupsTab)
