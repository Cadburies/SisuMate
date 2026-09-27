title: Watch schedule companion
desc: Plans crew watch slots and prompts for passages.
layer: platform
keywords: watch, schedule, rota, night watch, crew, prompts
kind: service
looks: -
reach: passage planning and watch checklists
needs: -
action: Builds a watch plan from crew and passage length with timed prompts.
expect: Each crew member gets fair watch slots with prompts.
uses: -
script: test/watch_companion_service_test.dart
source: lib/services/watch_companion_service.dart (WatchCompanionService, WatchCompanionPlan)
