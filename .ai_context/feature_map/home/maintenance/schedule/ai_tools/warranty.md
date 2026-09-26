title: Check warranty coverage
desc: Describe a failure and have the AI check it against your pasted warranty terms. Currently needs an AI key and a connection.
layer: ux
keywords: warranty, guarantee, claim, failure, coverage, ai
kind: dialog
looks: "Check warranty coverage" in the AI tools sheet; opens "AI: Warranty check".
reach: text:Maintenance > text:Yanmar 4JH45 - 250-Hour Engine Service > tip:AI tools: Raw Water Pump Service > text:Check warranty coverage
needs: network=online
action: Paste the warranty excerpt, describe the failure and tap Ask.
expect: "AI: Warranty check" with an Ask button is shown.
uses: system/ai/llm_client
script: maintenance
source: lib/ui/maintenance/warranty_check_dialog.dart (WarrantyCheckDialog); lib/ui/components/pasted_excerpt_check_dialog.dart
