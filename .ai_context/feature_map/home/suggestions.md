title: Suggestions card
desc: Up to a few boat suggestions on Home (overdue service, low stock, weather), each opening the screen that fixes it.
layer: ux
keywords: suggestions, tips, overdue, reminders, alerts, recommendations
kind: card
looks: "Suggestions" card under the readiness card (only when there is something to suggest), one row per suggestion.
reach: -
needs: -
action: Tap a suggestion to open the related module. Swipe the card away to hide it until the app restarts.
expect: The "Suggestions" card lists the current suggestions.
uses: system/logic/suggestion_engine
script: home
source: lib/ui/home/home_screen.dart (homeSuggestionsDismissedProvider)
