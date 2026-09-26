title: Save a place
desc: Bookmark the current weather location by name so you can pick it again later.
layer: ux
keywords: save, bookmark, favourite place, location, saved places
kind: button
looks: Bookmark button next to Use GPS; saved places appear as chips with a delete button.
reach: text:Weather > type:Latitude=-33.9 > type:Longitude=18.4 > type:Place name=Cape Town > tip:Save place
needs: -
action: Saves the named place; needs a place name and coordinates.
expect: "Saved places" lists "Cape Town" and a message confirms it.
uses: -
script: weather
source: lib/ui/weather/weather_screen.dart (_saveFavorite)
