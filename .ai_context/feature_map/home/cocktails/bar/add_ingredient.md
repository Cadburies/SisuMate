title: Add a bar ingredient
desc: Add your own bottle, mixer or garnish to My Bar. Pro only.
layer: ux
keywords: add bottle, bar ingredient, custom, spirit
kind: fab
looks: Round + button on My Bar.
reach: text:Cocktails > text:My Bar > wait:Absinthe > tip:Add custom ingredient
needs: tier=pro (on Free it explains that editing needs Pro)
action: Opens the add-ingredient form for the bar.
expect: The add-ingredient form opens.
uses: -
script: cocktails
source: lib/ui/cocktails/cocktails_screen.dart (CocktailsScreen)
