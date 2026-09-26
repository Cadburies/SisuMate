title: House recipes
desc: Your house syrups and pre-mixes (demerara, cinnamon, Don's Mix and more) with prep time and flavours.
layer: ux
keywords: house, syrups, premix, falernum, demerara, homemade
kind: screen
looks: "House" tab: syrup cards with description, flavour chips and prep time; + button.
reach: text:Cocktails > text:House > wait:Honey Syrup
needs: -
action: Tap a syrup for its recipe; + adds your own.
expect: Syrups such as "Demerara Syrup" and "Honey Syrup" are listed.
uses: -
script: cocktails
source: lib/ui/cocktails/cocktails_screen.dart (_SyrupsTab)
