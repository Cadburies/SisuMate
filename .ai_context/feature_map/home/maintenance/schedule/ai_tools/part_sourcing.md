title: Find a compatible part
desc: Asks the AI which part specs to look for and what kind of local supplier stocks them. Currently needs an AI key and a connection.
layer: ux
keywords: part, spare, sourcing, supplier, compatible, chandlery, ai
kind: dialog
looks: "Find a compatible part near me" in the AI tools sheet; opens "AI: Find a compatible part".
reach: text:Maintenance > text:Yanmar 4JH45 - 250-Hour Engine Service > tip:AI tools: Raw Water Pump Service > text:Find a compatible part near me
needs: network=online
action: Sends the task to your AI provider and lists matching part specs and supplier types.
expect: "AI: Find a compatible part" is shown.
uses: system/ai/llm_client
script: maintenance
source: lib/ui/maintenance/part_sourcing_dialog.dart (PartSourcingDialog)
