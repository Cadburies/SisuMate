title: Free edits allowance
desc: Free users get a small number of edits on item pages (e.g. completing a checklist item) before Pro is required.
layer: pro
keywords: free edits, preview, limit, counter, trial
kind: service
looks: -
reach: Complete / Edit on an item page while on Free
needs: tier=free_limited
action: Counts edits on the device and shows "Free preview: N edit(s) left" until the allowance runs out.
expect: After the allowance, further edits ask for Pro.
uses: system/pro/paywall
script: test/free_edit_gate_test.dart
source: lib/services/free_edit_gate.dart (FreeEditGate)
