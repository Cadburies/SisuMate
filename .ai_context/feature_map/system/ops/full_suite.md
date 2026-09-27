title: Full regression suite
desc: The post-task gate: secret scan, analyze, all host tests (including every Feature Map reach), live RLS, schema parity and the integration smoke.
layer: ops
keywords: tests, suite, ci, regression, gate
kind: script
looks: -
reach: run ./scripts/run_full_suite.sh (flags --skip-live, --skip-integration, --device)
needs: -
action: Runs each stage in order and stops on the first failure.
expect: "==> full suite green".
uses: system/ops/secret_scan
script: -
source: scripts/run_full_suite.sh
