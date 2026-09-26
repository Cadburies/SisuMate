title: A service schedule
desc: The tasks in one service schedule, each ticked off as you do it, with AI tools and an "add spare" shortcut on every task.
layer: ux
keywords: service, tasks, schedule, oil change, impeller, filter, engine
kind: screen
looks: Schedule title bar and task rows, each with a purple sparkle badge (AI tools) and a brown box badge (add spare).
reach: text:Maintenance > text:Yanmar 4JH45 - 250-Hour Engine Service
needs: -
action: Tap a task for its full page; swipe left to complete, right to hide. Completing a task can offer to use a linked spare.
expect: Tasks such as "Raw Water Pump Service" are listed.
uses: shared/swipe/complete, shared/swipe/hide, shared/check_page_viewer, shared/import_export
script: maintenance
source: lib/ui/maintenance/maintenance_items_screen.dart (MaintenanceItemsScreen); lib/ui/maintenance/linked_spare_prompt.dart (LinkedSparePrompt)
