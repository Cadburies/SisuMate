title: Explain a maintenance task
desc: Shows a bundled offline note on why a maintenance task matters. Improve with AI is optional when a key and a connection are available.
layer: ux
keywords: explain, what is, why, ai, help, task, offline
kind: dialog
looks: "Explain this task" in the AI tools sheet; opens "AI: <task>".
reach: text:Maintenance > text:Yanmar 4JH45 - 250-Hour Engine Service > tip:AI tools: Raw Water Pump Service > text:Explain this task
needs: -
action: Opens an offline note for the task. Improve with AI sends only the title and description, and only if you ask.
expect: "AI: Raw Water Pump Service" opens with an offline note about the impeller. Go to Settings appears only after Improve with AI when no key is set.
uses: system/ai/llm_client
script: maintenance
source: lib/ui/maintenance/maintenance_ai_explainer_dialog.dart (MaintenanceAiExplainerDialog); lib/services/maintenance_local_explain.dart
