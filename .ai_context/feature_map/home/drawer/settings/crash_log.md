title: Upload crash log
desc: Sends the errors stored on this device to the developer so they can be fixed.
layer: ux
keywords: crash, errors, log, report bug, send logs, support
kind: menu
looks: "Upload crash log / Send stored errors from this device so we can fix them" under Account.
reach: tip:Menu > text:Settings > text:Upload crash log
needs: -
action: Uploads pending error reports when signed in; otherwise says there is nothing to upload.
expect: A message reports how many logs were sent, or "Nothing to upload (…)".
uses: system/errors/error_log
script: settings
source: lib/ui/settings/settings_screen.dart (_handleUploadCrashLog)
