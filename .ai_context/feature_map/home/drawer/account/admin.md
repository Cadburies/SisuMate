title: Developer console
desc: Developer-only console for subscriptions, usage and purging stale cloud data.
layer: ux
keywords: admin, developer, console, subscriptions, purge, usage
kind: screen
looks: "Developer" row in the menu, only for the developer account; the console lists users with warning-email and purge buttons.
reach: tip:Menu > text:Developer
needs: auth=developer · platform=device
action: Every action is re-checked on the server.
expect: The developer console lists subscriptions and usage.
uses: -
script: test/admin_grace_period_row_test.dart
source: lib/ui/admin/admin_screen.dart (AdminScreen)
