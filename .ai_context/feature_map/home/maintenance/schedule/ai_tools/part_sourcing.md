title: Find a compatible part
desc: Offline part-spec and supplier-type hints for a task. A city only names where to ask. Improve with AI is optional and does not check live stock.
layer: ux
keywords: part, spare, sourcing, supplier, compatible, chandlery, ai, offline
kind: dialog
looks: "Find a compatible part near me" in the AI tools sheet; opens "AI: Find a compatible part".
reach: text:Maintenance > text:Yanmar 4JH45 - 250-Hour Engine Service > tip:AI tools: Raw Water Pump Service > text:Find a compatible part near me
needs: -
action: Shows an offline part guide from the task text. A city can be detected or typed. Improve with AI is optional.
expect: "AI: Find a compatible part" is shown with an offline part guide.
uses: system/ai/llm_client
script: maintenance
source: lib/ui/maintenance/part_sourcing_dialog.dart (PartSourcingDialog); lib/services/maintenance_local_explain.dart
