title: Export to a file
desc: Save this module's current items as a JSON file you can keep or share.
layer: ux
keywords: export, file, json, save, backup, share
kind: menu
looks: "Export to file" row in the import/export sheet.
reach: text:Shopping > tip:Import / Export > text:Export to file
needs: platform=device
action: Writes the items to a JSON file and opens the phone's share or save sheet.
expect: The share or save sheet opens with the JSON file.
uses: system/db/import_export
script: -
source: lib/ui/components/import_export.dart (ModuleImportExport)
