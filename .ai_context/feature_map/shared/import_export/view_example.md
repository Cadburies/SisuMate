title: View the import format
desc: Shows an example of the file format this module imports, so you can prepare your own.
layer: ux
keywords: example, format, json, sample, template, how to import
kind: dialog
looks: "View example format" row in the import/export sheet; opens "<Module> — example".
reach: text:Shopping > tip:Import / Export > text:View example format
needs: -
action: Opens the example in a dialog with a Close button.
expect: "Shopping — example" is shown.
uses: -
script: shared_chrome
source: lib/ui/components/import_export.dart (ModuleImportExport)
