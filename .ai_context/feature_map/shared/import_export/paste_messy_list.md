title: Paste a messy list
desc: Paste any text or CSV and have it turned into items for this module. Pro only.
layer: ux
keywords: paste, messy, text, csv, ai, parse, import, convert
kind: dialog
looks: "Paste messy list" row in the import/export sheet; opens "AI: Paste messy list" with Cancel and Parse.
reach: text:Shopping > tip:Import / Export > text:Paste messy list
needs: tier=pro (on Free it opens the upgrade page)
action: Parse turns the pasted text into items on the device; with an AI key and a connection it can do a better job.
expect: The "AI: Paste messy list" dialog is shown.
uses: system/ai/messy_import
script: shared_chrome
source: lib/ui/components/ai_messy_import_dialog.dart (AiMessyImportDialog)
