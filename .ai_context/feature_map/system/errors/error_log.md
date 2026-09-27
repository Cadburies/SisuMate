title: Error log capture
desc: Every caught error, Flutter error and uncaught async error is written to a local error log with a fingerprint, deduplicated, with secrets redacted; it never syncs.
layer: errors
keywords: errors, crash, log, fingerprint, dedupe, redaction
kind: service
looks: -
reach: automatic on any logged exception or warning; uploaded via Settings → Upload crash log
needs: -
action: logException / logWarning with a '<module>: <operation>' context; the triage script turns each new fingerprint into one GitHub issue.
expect: Repeated errors collapse to one fingerprint; tokens and keys are redacted.
uses: -
script: test/error_log_service_test.dart
source: lib/services/error_log_service.dart (ErrorLogService); lib/services/provider_breadcrumbs.dart
