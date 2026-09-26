title: Explain a maintenance task
desc: Asks the AI to explain what a task involves and why it matters. Currently needs an AI key and a connection.
layer: ux
keywords: explain, what is, why, ai, help, task
kind: dialog
looks: "Explain this task" in the AI tools sheet; opens "AI: <task>".
reach: text:Maintenance > text:Yanmar 4JH45 - 250-Hour Engine Service > tip:AI tools: Raw Water Pump Service > text:Explain this task
needs: network=online (without an AI key it says to add one in Settings)
action: Sends the task title and description to your AI provider and shows the answer.
expect: "AI: Raw Water Pump Service" opens; with no key it offers "Go to Settings".
uses: system/ai/llm_client
script: maintenance
source: lib/ui/maintenance/maintenance_ai_explainer_dialog.dart (MaintenanceAiExplainerDialog)
