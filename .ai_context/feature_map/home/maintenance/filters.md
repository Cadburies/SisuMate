title: Maintenance filters
desc: Show or hide maintenance tasks you have hidden, plus the shared data and account options.
layer: ux
keywords: filter, hidden, show hidden, menu, options
kind: drawer
looks: Menu on the Maintenance screen titled "Filters & Options" with a "Show Hidden Items" switch.
reach: text:Maintenance > tip:Menu
needs: -
action: Toggle hidden tasks; the rest is the shared main menu.
expect: "Show Hidden Items" is shown.
uses: home/drawer
script: maintenance
source: lib/ui/maintenance/maintenance_screen.dart (MaintenanceScreen)
