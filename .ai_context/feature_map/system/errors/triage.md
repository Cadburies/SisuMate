title: Error and crash triage
desc: Pulls the error log (Android or iOS) or native .ips crash reports off a connected device and files one deduplicated GitHub issue per new fingerprint.
layer: errors
keywords: triage, crash reports, ips, github issues, device logs
kind: script
looks: -
reach: run scripts/triage_error_logs.sh (Android), scripts/triage_error_logs_ios.sh (iOS) or scripts/triage_ips_crashes.sh with a device connected
needs: platform=device
action: Dumps, dedupes and files issues on a local copy only; idempotent via a fingerprint marker search.
expect: One new issue per unseen fingerprint; rerunning files nothing new.
uses: system/errors/error_log
script: -
source: scripts/triage_error_logs.sh; scripts/triage_error_logs_ios.sh; scripts/triage_ips_crashes.sh; scripts/_ips_crash.py
