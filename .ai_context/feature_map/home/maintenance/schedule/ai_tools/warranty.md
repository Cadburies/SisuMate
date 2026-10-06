title: Check warranty coverage
desc: Check a failure against warranty wording you paste. An offline keyword reading comes first. Improve with AI is optional.
layer: ux
keywords: warranty, guarantee, claim, failure, coverage, ai, offline
kind: dialog
looks: "Check warranty coverage" in the AI tools sheet; opens "AI: Warranty check".
reach: text:Maintenance > text:Yanmar 4JH45 - 250-Hour Engine Service > tip:AI tools: Raw Water Pump Service > text:Check warranty coverage
needs: -
action: Paste the warranty excerpt, describe the failure, and tap Check offline. Improve with AI is optional.
expect: "AI: Warranty check" with a Check offline button is shown.
uses: system/ai/llm_client
script: maintenance
source: lib/ui/maintenance/warranty_check_dialog.dart (WarrantyCheckDialog); lib/ui/components/pasted_excerpt_check_dialog.dart (PastedExcerptCheckDialog); lib/services/pasted_excerpt_local_check.dart
