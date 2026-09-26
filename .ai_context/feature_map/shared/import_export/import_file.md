title: Import from a file
desc: Load items into this module from a JSON file on your device.
layer: ux
keywords: import, file, json, load, restore, backup
kind: menu
looks: "Import from file" row in the import/export sheet.
reach: text:Shopping > tip:Import / Export > text:Import from file
needs: platform=device
action: Opens the phone's file picker; the chosen file's items are added to this module.
expect: The file picker opens; imported items then appear in the list.
uses: system/db/import_export
script: -
source: lib/ui/components/import_export.dart (ModuleImportExport)
