title: AI provider client (bring your own key)
desc: Calls the boat's chosen AI provider (OpenAI, xAI, Anthropic, Moonshot) with the user's own key, with web search where supported, citations, and usage/cost tracking.
layer: ai
keywords: llm, ai, byok, api key, openai, anthropic, grok, kimi, usage
kind: service
looks: -
reach: any "Improve with AI" / AI dialog, only when online with a key
needs: network=online
action: Builds a privacy-minimal payload, calls the provider, tracks monthly usage per device. Optional enrichment only: every AI feature must work offline first (#286); known exceptions are tracked in #402 and #405.
expect: No key or no connection returns a clear "not configured / offline" result, never a crash.
uses: -
script: test/llm_client_service_test.dart
source: lib/services/llm_client_service.dart (LlmClientService, LlmResult); lib/services/llm_payload_builder.dart (LlmPayloadBuilder); lib/services/llm_usage_tracker.dart (LlmUsageTracker)
