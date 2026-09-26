title: A safety briefing
desc: The points of one briefing (welcome, heads, lifejackets and so on), each ticked off as you brief the crew.
layer: ux
keywords: briefing, points, crew, safety talk, welcome aboard
kind: screen
looks: Briefing title bar and a list of points, each with a small purple AI badge; + button bottom-right.
reach: text:Safety > text:Day Trip Safety Briefing
needs: -
action: Tap a point for its full page; swipe left to complete it, right to hide it.
expect: Points such as "Sunscreen" are listed.
uses: shared/swipe/complete, shared/swipe/hide, shared/check_page_viewer, shared/import_export
script: safety
source: lib/ui/safety/safety_briefing_screen.dart (SafetyBriefingItemsScreen)
