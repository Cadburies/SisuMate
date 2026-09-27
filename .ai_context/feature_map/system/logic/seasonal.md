title: Seasonal produce
desc: What is in season this month, used by Chef's Corner suggestions.
layer: logic
keywords: season, in season, produce, month
kind: service
looks: -
reach: Chef's Corner
needs: -
action: Returns in-season items for the month (and hemisphere).
expect: September lists items such as tomatoes and apples.
uses: -
script: test/seasonal_service_test.dart
source: lib/services/seasonal_service.dart (SeasonalService)
