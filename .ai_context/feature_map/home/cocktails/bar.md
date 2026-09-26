title: My Bar
desc: Every bottle, mixer and garnish, with what is aboard; drives which cocktails you can make.
layer: ux
keywords: bar, bottles, spirits, mixers, stock, liquor
kind: screen
looks: "My Bar" tab: ingredient rows sorted A–Z with flavour chips.
reach: text:Cocktails > text:My Bar > wait:Absinthe
needs: -
action: Tap a bottle for its page; swipe left for In stock, right for Shopping.
expect: Bar ingredients such as "Absinthe" are listed.
uses: shared/ingredient_detail, shared/swipe/in_stock, shared/swipe/add_to_shopping
script: cocktails
source: lib/ui/cocktails/cocktails_screen.dart (CocktailsScreen)
