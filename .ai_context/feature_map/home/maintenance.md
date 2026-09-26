title: Maintenance
desc: Service schedules for the boat (Yanmar 50, 250, 500 and 1000-hour services and your own), plus the engine-hours log.
layer: ux
keywords: maintenance, service, engine, yanmar, schedule, hours, repairs
kind: screen
looks: Grid of service schedules with a clock button for the engine hours log in the title bar.
reach: text:Maintenance
needs: -
action: Tap a schedule to open its tasks; the clock button opens the engine hours and service log.
expect: "Yanmar 4JH45 - 250-Hour Engine Service" and the other services are listed.
uses: -
script: maintenance
source: lib/ui/maintenance/maintenance_screen.dart (MaintenanceScreen)
