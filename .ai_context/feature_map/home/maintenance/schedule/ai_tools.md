title: Maintenance AI tools
desc: Per-task tools to explain a task, check warranty coverage, or find a compatible part.
layer: ux
keywords: ai, explain, warranty, part, sourcing, help
kind: sheet
looks: Small purple sparkle badge on the top-right of each task row; opens a sheet with three tools.
reach: text:Maintenance > text:Yanmar 4JH45 - 250-Hour Engine Service > tip:AI tools: Raw Water Pump Service
needs: -
action: Opens the sheet with Explain this task, Check warranty coverage and Find a compatible part near me.
expect: The three tools are listed.
uses: -
script: maintenance
source: lib/ui/maintenance/maintenance_items_screen.dart (_showAiMenu)
