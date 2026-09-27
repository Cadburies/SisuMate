title: Import and export of module data
desc: JSON export of a module's items and import back (from file or parsed pasted text), with validation and a clear error for bad files.
layer: db
keywords: import, export, json, backup, restore, file
kind: service
looks: -
reach: import/export sheet on a module (Import from file, Export to file, Paste messy list)
needs: -
action: Parses and validates a batch, then persists it through the module's repository.
expect: Export then import into an empty database round-trips; malformed JSON raises an import error, not a crash.
uses: -
script: test/import_roundtrip_test.dart
source: lib/services/import_service.dart (ImportBatch, ImportException); lib/ui/components/import_export.dart (ModuleImportExport)
