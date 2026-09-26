title: Import and export
desc: Bring a list in from a file or pasted text, or save the current list to a file, on any module that has the import/export button.
layer: ux
keywords: import, export, file, json, backup, paste, csv, share, template
kind: sheet
looks: Up/down-arrow button in the title bar; opens a sheet with Import from file, Paste messy list, Export to file, View example format and Export sample template.
reach: text:Shopping > tip:Import / Export
needs: -
action: Opens the import/export sheet for the current module.
expect: The sheet lists "Import from file" and "Export to file".
uses: system/db/import_export
script: shared_chrome
source: lib/ui/components/import_export.dart (ModuleImportExport)
