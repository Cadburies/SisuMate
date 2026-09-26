title: Travel and entry safety
desc: Ask about entry rules and travel safety for your crew's nationalities at a destination. Currently needs an AI key and a connection.
layer: ux
keywords: travel, entry, visa, immigration, clearance, nationality, safety, ai
kind: dialog
looks: Purple sparkle button in the Crew title bar; opens "AI: Travel & entry safety".
reach: text:Crew & Contacts > tip:AI: Travel & entry safety
needs: network=online
action: Uses only nationalities (never passport details) and asks your AI provider with web search.
expect: "AI: Travel & entry safety" with an Ask button is shown.
uses: system/ai/llm_client
script: crew
source: lib/ui/crew/travel_safety_dialog.dart
