title: Free vs Pro gates
desc: The Free/Pro matrix enforced across modules (view everything free; completing, editing, sync, crew sharing, extra boats and the community library need Pro).
layer: pro
keywords: free, pro, gates, matrix, limits, upgrade
kind: service
looks: -
reach: every gated action; the full list lives in access_tiers.md
needs: -
action: Each gate reads isProProvider; Free taps show a Pro-required prompt or open the paywall.
expect: The gate matrix test passes for every module.
uses: system/pro/revenuecat, system/pro/paywall
script: test/pro_free_gate_matrix_test.dart
source: lib/core/di.dart (isProProvider); .ai_context/access_tiers.md
