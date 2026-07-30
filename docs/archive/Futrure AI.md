# Sisu Mate AI Integration Specifications and Implementation Guide

This document details specifications, including detailed requirements, reasoning for design choices, step-by-step implementation guides, and robustness measures. This aligns with PRD Section 10: AI Integration (Free & Pro Tiers). The Free tier focuses on on-device AI for offline, privacy-focused functionality, while the Pro tier uses cloud-based AI for advanced features. Pro users have access to all Free-tier AI features in addition to Pro-tier AI enhancements. To enhance robustness, Pro features include offline fallbacks to equivalent Free-tier capabilities, with clear user notifications (e.g., via app alerts or UI banners). For Pro integrations, we've prioritized the current best free AI APIs where available (based on 2025 standards, such as Google AI Studio for Gemini models, Hugging Face Inference API, OpenRouter for free LLM access, and Open-Meteo for weather data) to minimize costs while maintaining quality. If no fully free API fits, low-cost tiers (e.g., OpenWeatherMap free tier) are suggested. Implementation assumes a Flutter-based app with Supabase backend, as referenced in the original document. The top status bar must follow the PRD specifications.

## Overview

- **Free Tier**: Ad-supported, local-only, offline-capable only. Uses lightweight on-device models (e.g., TensorFlow Lite, ML Kit) for basic AI enhancements.
- **Pro Tier**: Subscription-based, ad-free, with cloud sync and advanced AI. Leverages free or low-cost cloud APIs (e.g., Google AI Studio for LLMs, Open-Meteo for weather). Pro users have full access to all Free-tier AI features plus Pro enhancements. Includes fallbacks: If offline or API fails, revert to Free-tier equivalent and notify user (e.g., "Offline mode: Using basic local AI. Upgrade or connect for full Pro features."). Update status bar to reflect offline status as per PRD.
- **General Reasoning**: Free tier prioritizes privacy (no data leaves device) and low latency. Pro tier adds value through data-intensive AI, justifying monetization. Robustness ensures seamless UX (e.g., graceful degradation, error handling). Ethical considerations: Anonymize data, obtain consent for any collection.
- **Tech Stack**: Flutter for cross-platform (iOS/Android), TensorFlow Lite/ML Kit for on-device, HTTP/Dio for API calls, Supabase for sync/storage. Integrate RevenueCat for subscription checks to enable/disable Pro features and ads.
- **Testing and Rollout**: Unit test AI accuracy (aim for 85%+ on safety-critical features). Beta test with boating users. Prioritize 1-2 features per development sprint. Ensure ads are only shown to Free users and never interfere with safety-critical flows (e.g., Checklists, Safety Briefings, Captain’s Log during passage), as per PRD.

## Free Version: On-Device AI Integration

These features run entirely locally, ensuring offline availability and data privacy. No internet or subscription required. Pro users retain access to these features alongside Pro enhancements.

### 1. Image Recognition for Inventory and Checklists

#### Specification

- **Requirements**: Use device camera to scan boat parts (e.g., filters, impellers). Auto-categorize items, suggest quantities based on predefined patterns, and flag low stock. Integrate into Inventory/Shopping & Spares screens. Limit to basic categories (e.g., 10-20 common items). Output: Populated form fields with confidence score (>70% threshold). In Free tier, editing is restricted per PRD (e.g., view-only for checklists); prompt upgrade for full CRUD.
- **Inputs/Outputs**: Input: Camera photo. Output: Category label, suggested quantity, stock alert.
- **Constraints**: Offline only; model size <50MB for quick loading.

#### Reasoning

- Enhances user efficiency during onboard audits without cloud dependency, aligning with Free tier's local focus. On-device processing protects privacy (e.g., no photo uploads). Chosen libraries (ML Kit/TensorFlow Lite) are mature, free, and optimized for mobile.

#### Step-by-Step Implementation

1. **Setup Dependencies**: Add `ml_kit` (for Android/iOS) or `tflite_flutter` to `pubspec.yaml`. Install camera plugin (`camera` package).
2. **Prepare Model**: Download pre-trained MobileNet from TensorFlow Hub. Fine-tune locally in Python (using TensorFlow) on marine datasets (e.g., Kaggle Boat Types). Convert to .tflite: `converter = tf.lite.TFLiteConverter.from_saved_model(model); tflite_model = converter.convert();` Bundle in app assets.
3. **Integrate in App**: In Item Detail screen, add "Scan Item" button. On tap: Open camera, capture image, run inference: `interpreter.run(inputImage, outputBuffer);` Parse results to populate fields (e.g., if label == 'impeller', suggest quantity=2). Check RevenueCat for Pro status; if Free, show upgrade prompt for edits.
4. **Test**: Simulate scans with sample images; measure accuracy and latency (<2s).

#### Robustness Measures

- Error Handling: If model fails (e.g., low light), fallback to manual entry with toast: "Scan failed—try better lighting."
- Privacy: Process images locally; delete temp files immediately.
- Edge Cases: Handle varying lighting/angles via data augmentation in training. Limit to supported devices (check API availability). Update status bar for offline/Free as per PRD.

### 2. Voice-to-Text for Captain’s Log and Notes

#### Specification

- **Requirements**: Hands-free dictation for log entries, notes, or comments (e.g., "Engine check complete"). Real-time transcription, limited to basic English (extendable). Integrate microphone button in Captain’s Log/Item Detail screens. In Free tier, limit to view-only for logs per PRD.
- **Inputs/Outputs**: Input: Audio stream. Output: Transcribed text inserted into field.
- **Constraints**: Offline; short sessions (<1min) to conserve battery.

#### Reasoning

- Ideal for rough-sea usage where typing is error-prone. Uses device-native APIs for zero-cost, high-accuracy baseline, reducing custom training needs.

#### Step-by-Step Implementation

1. **Setup Dependencies**: Use `speech_to_text` Flutter package (wraps iOS Speech/Android SpeechRecognizer).
2. **Prepare Model**: No custom model needed initially; use device defaults. For boating terms, fine-tune Whisper Tiny (Hugging Face) in Python, convert to TFLite.
3. **Integrate in App**: Add mic icon; on press: Initialize listener `speech.initialize(); speech.listen(onResult: (result) => updateTextField(result.recognizedWords));` Stop on release or timeout. For Free users, restrict edits and show upgrade prompt.
4. **Test**: Record sample phrases; evaluate word error rate (<10%).

#### Robustness Measures

- Error Handling: If no speech detected, prompt "Speak clearly." Fallback to keyboard if API unavailable.
- Privacy: Audio processed locally; no storage without consent.
- Edge Cases: Noise cancellation via device mic settings; handle accents with optional fine-tuning. Align with PRD swipe actions and status bar updates.

### 3. Predictive Maintenance Alerts

#### Specification

- **Requirements**: Analyze local logs (e.g., engine hours, fuel) to predict issues (e.g., "Oil change due in 50 hours"). Trigger alerts on data entry in Maintenance Scheduler/Fuel & Water Log.
- **Inputs/Outputs**: Input: Local DB entries. Output: Alert notifications with suggestions.
- **Constraints**: Simple models; run on data updates.

#### Reasoning

- Prevents breakdowns using historical patterns, adding value without cloud. Lightweight regression fits mobile constraints.

#### Step-by-Step Implementation

1. **Setup Dependencies**: Add `tflite_flutter` and `sqflite` for local DB (align with Isar/Drift per PRD).
2. **Prepare Model**: Train Linear Regression in Python (TensorFlow) on simulated data. Convert to TFLite.
3. **Integrate in App**: On log save: Load model, input data vector, run inference: Get prediction, show alert if threshold met (e.g., via `FlutterLocalNotifications`). For Free users, limit to basic views.
4. **Test**: Input test logs; verify alert accuracy.

#### Robustness Measures

- Error Handling: If data insufficient, show "Need more logs for predictions."
- Privacy: All data local.
- Edge Cases: Handle sparse data with default assumptions (e.g., average usage). Ensure no ads in safety flows per PRD.

### 4. Smart Suggestions for Menus and Cocktails

#### Specification

- **Requirements**: Suggest recipes based on local inventory (e.g., "Rum + lime = Mojito"). Cross-reference on app open in Menus/Cocktails.
- **Inputs/Outputs**: Input: Inventory DB. Output: List of 3-5 suggestions.
- **Constraints**: Rule-based or simple ML; fast execution.

#### Reasoning

- Boosts usability with personalized, offline recommendations. Basic filtering avoids complex training.

#### Step-by-Step Implementation

1. **Setup Dependencies**: Use `sqflite` for DB (align with Isar/Drift per PRD).
2. **Prepare Model**: Bundle recipe dataset; use scikit-learn for simple filtering model, convert if needed.
3. **Integrate in App**: On screen load: Query DB, match ingredients, display suggestions in list view. Apply consistent swipe actions per PRD.
4. **Test**: Mock inventory; check suggestion relevance.

#### Robustness Measures

- Error Handling: If no matches, suggest "Add more items."
- Privacy: Local only.
- Edge Cases: Handle empty inventory with generic tips.

## Pro Version: Online AI Integration

These features require internet and Pro subscription. Pro users have access to Free-tier AI plus these enhancements. Use free APIs where possible (e.g., Google AI Studio for LLMs). Include offline fallback: Detect connectivity (e.g., via `connectivity_plus` package), switch to Free equivalent, notify user (e.g., banner: "Offline: Falling back to basic local AI. Connect for Pro enhancements."), and update status bar to Amber for Pro + Offline per PRD.

### 1. AI-Powered Passage Planning and Weather Analysis

#### Specification

- **Requirements**: Input route; AI optimizes with weather/marine data (e.g., "Reroute 10° west for 15% fuel savings"). Integrate PredictWind or free alternatives; display on maps in Weather & Passage app.
- **Inputs/Outputs**: Input: User route. Output: Optimized plan with maps/alerts.
- **Constraints**: API calls on sync; limit to 10/day for free tiers.

#### Reasoning

- Adds premium navigation value. Free weather APIs (Open-Meteo, NWS) provide marine data; pair with LLM (Google AI Studio) for analysis to keep costs low.

#### Step-by-Step Implementation

1. **Setup Dependencies**: Add `http` for APIs, `flutter_map` for display.
2. **API Selection**: Use Open-Meteo (free, open-source marine weather) + Google AI Studio (free Gemini API for analysis).
3. **Integrate in App**: On input: Fetch weather via Open-Meteo API (`GET /marine?lat=...`), send to Gemini prompt ("Optimize route: [data]"), parse response, show on map. Check RevenueCat for Pro.
4. **Fallback**: If offline, use local basic alerts; notify user and update status bar.
5. **Test**: Simulate routes; check optimization logic.

#### Robustness Measures

- Error Handling: API fail → Fallback + retry button.
- Privacy: Anonymize location data.
- Edge Cases: Rate limits → Cache recent data. Align with PRD multiple boats support.

### 2. Diagnostic Assistant for Maintenance and Issues

#### Specification

- **Requirements**: Chat-based: Input symptoms (e.g., "Engine vibrating"); suggest diagnoses/parts. Personalize with synced history in Maintenance Scheduler.
- **Inputs/Outputs**: Input: Text description. Output: Step-by-step advice.
- **Constraints**: Chat history limited to session.

#### Reasoning

- Interactive troubleshooting justifies Pro. Use free LLM API (Hugging Face or OpenRouter) for generative responses, fine-tuned on marine data.

#### Step-by-Step Implementation

1. **Setup Dependencies**: Add `flutter_chat_ui` for interface.
2. **API Selection**: Hugging Face Inference (free tier for Mistral models).
3. **Integrate in App**: Send prompt to API (`POST /inference` with "Diagnose: [symptoms] + history"), display response.
4. **Fallback**: Offline → Basic local suggestions; notify and update status bar.
5. **Test**: Query samples; evaluate response accuracy.

#### Robustness Measures

- Error Handling: Invalid response → "Try rephrasing."
- Privacy: Send minimal data; user consent.
- Edge Cases: Handle ambiguous inputs with clarification prompts.

### 3. Generative Custom Checklists and Briefings

#### Specification

- **Requirements**: Input prompt (e.g., "Briefing for family trip"); generate tailored content with boat data. Integrate into Checklists/Safety Briefings.
- **Inputs/Outputs**: Input: Natural language. Output: Editable script saved to cloud.
- **Constraints**: One generation per sync.

#### Reasoning

- Custom safety content adds Pro exclusivity. Free LLM (Google AI Studio) enables efficient generation.

#### Step-by-Step Implementation

1. **Setup Dependencies**: Use `http` and Supabase SDK.
2. **API Selection**: Google AI Studio (free for Gemini).
3. **Integrate in App**: Send prompt to API, save output to Supabase, display editable. For Free, block creation per PRD.
4. **Fallback**: Offline → Pre-bundled templates; notify and update status bar.
5. **Test**: Generate samples; review for relevance.

#### Robustness Measures

- Error Handling: API down → Cached templates.
- Privacy: Strip sensitive data from prompts.
- Edge Cases: Long prompts → Truncate with warning.

### 4. Anomaly Detection in Logs and Crew Management

#### Specification

- **Requirements**: Scan synced logs for issues (e.g., "Unusual fuel burn"); suggest schedules. Integrate into Captain’s Log/Crew & Contacts.
- **Inputs/Outputs**: Input: Cloud logs. Output: Alerts/notifications.
- **Constraints**: Batch on sync.

#### Reasoning

- Proactive insights monetize Pro. Use free ML via Hugging Face or simple cloud scripts.

#### Step-by-Step Implementation

1. **Setup Dependencies**: Supabase functions for batching.
2. **API Selection**: OpenRouter (free anomaly models) or Google AI Studio for pattern analysis.
3. **Integrate in App**: On sync: Fetch logs, send to API, push notifications via Firebase.
4. **Fallback**: Offline → Local basic checks; notify and update status bar.
5. **Test**: Inject anomalies; verify detection.

#### Robustness Measures

- Error Handling: No anomalies → "All clear."
- Privacy: Anonymized logs.
- Edge Cases: Large datasets → Paginate API calls.

## Getting Training Data, Training Models, and Timelines

This section updates the original with refined estimates, incorporating free APIs to reduce custom training needs (e.g., use pre-trained via Hugging Face). Timelines assume solo developer; add for teams. Ensure integration aligns with PRD tech stack (e.g., Isar for local DB, Supabase for sync).

### On-Device AI (Free Tier)

- **General**: Minimal custom training; leverage pre-trained. Total rollout: 4-6 weeks phased.

1. **Image Recognition**: Data: Kaggle/Roboflow (free). Training: 2-4h on laptop. Timeline: 2-3 weeks (reduced by pre-trained models).
2. **Voice-to-Text**: Data: Common Voice (free). Training: 1-2h. Timeline: 1 week.
3. **Predictive Maintenance**: Data: NOAA/ICOADS (free). Training: 4-8h. Timeline: 2 weeks.
4. **Smart Suggestions**: Data: RecipeNLG (free). Training: 1-2h. Timeline: 1 week.

### Online AI (Pro Tier)

- **General**: Favor API fine-tuning (e.g., Google AI Studio free tier). Total: 6-8 weeks.

1. **Passage Planning**: Data: NOAA/Spire (free). Training: 8-24h via cloud (free tiers). Timeline: 3-4 weeks.
2. **Diagnostic Assistant**: Data: BoatUS forums (scraped ethically). Fine-tune via Hugging Face (free). Timeline: 2-3 weeks.
3. **Generative Checklists**: Data: USCG manuals (free). Timeline: 2 weeks.
4. **Anomaly Detection**: Data: ICOADS (free). Timeline: 3 weeks.

**Tips**: Prototype with free APIs first (cuts time 50%). Monitor API usage to stay in free tiers. For help, consult docs or communities. If needed, budget $100-500 for cloud compute beyond free limits. Ensure all implementations check for Pro status via RevenueCat and handle ads/Free restrictions per PRD.
