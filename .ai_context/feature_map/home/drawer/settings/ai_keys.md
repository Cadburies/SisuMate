title: AI API keys
desc: Add your own OpenAI, xAI (Grok), Anthropic (Claude) or Moonshot (Kimi) key for the boat, optionally shared with crew, and see this month's AI usage.
layer: ux
keywords: ai, api key, openai, grok, claude, kimi, byok, usage
kind: dialog
looks: "AI API Keys" row (with the boat active) opens a dialog with one field per provider and a "Share with crew" switch.
reach: tip:Menu > text:Settings > tip:Choose active boat > text:My Boat > text:AI API Keys
needs: -
action: Save stores the keys for this boat; every AI feature works without a key and uses it only as an optional improvement.
expect: The "AI API Keys" dialog lists OpenAI, xAI (Grok), Anthropic (Claude) and Moonshot (Kimi).
uses: system/ai/llm_client
script: settings
source: lib/ui/settings/llm_api_key_dialog.dart
