title: Reset to factory
desc: Restores the original bundled checklists and content after asking you to confirm.
layer: ux
keywords: reset, factory, restore, original, start over, wipe
kind: dialog
looks: "Reset to Factory" row in the menu; opens a "Factory Reset" dialog with Cancel and a red Reset.
reach: tip:Menu > text:Reset to Factory
needs: -
action: Reset restores the bundled content to its original state; Cancel closes the dialog.
expect: The "Factory Reset" dialog with Cancel and Reset is shown.
uses: system/db/factory_reset
script: home
source: lib/ui/components/common_drawer.dart (_handleFactoryReset)
