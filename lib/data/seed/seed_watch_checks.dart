import 'checklist_drift_seed.dart';
import '../../models/models.dart';

final watchId = 'watchId';

Future<void> seedWatchChecks(String defaultBoatSupabaseId) async {
  // ===================================================================
  // CHECKLIST GROUP - Watch
  // ===================================================================
  final group = ChecklistGroup() 
    ..supabaseId = watchId
    ..boatSupabaseId = defaultBoatSupabaseId
    // ..name = 'On-Watch Monitoring Checks' // Undefined setter, commented out temporarily
    // ..icon = 'binoculars' // Undefined setter, commented out temporarily
    ..title = 'On-Watch Monitoring Checks'
    ..iconName = 'binoculars'
    ..sortOrder = 7
    ..appType = 'checklist'
    ..isBundled = true;

  await seedChecklistGroupToDrift(group);

  // ===================================================================
  // CHECKLIST ITEMS - Watch
  // ===================================================================
  final items = <ChecklistItem>[];

  // Helper to reduce boilerplate
  void add(String groupId, String name, String description, String assetName) {
    items.add(
      ChecklistItem()
        ..supabaseId =
            '${groupId}_${name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '_')}'
        ..groupSupabaseId = groupId
        // ..name = name // Undefined setter, commented out temporarily
        ..title = name
        ..description = description
        ..assetName = assetName
        ..isCompleted = false
        // ..expiryDate = null // Undefined setter, commented out temporarily
        ..isHidden = false
        ..isPermanentlyDeleted = false
        ..sortOrder = items.length,
    );
  }

  add(
    watchId,
    'VHF Radio Watch',
    'Monitor VHF Channel 16 for distress calls and maintain listening watch on working channel.',
    'radio',
  );
  add(
    watchId,
    'AIS Targets',
    'Monitor AIS display for nearby vessel traffic and potential collision threats.',
    'radar',
  );
  add(
    watchId,
    'Radar Watch',
    'Use radar to monitor for contacts, especially in reduced visibility.',
    'radar',
  );
  add(
    watchId,
    'Visual Lookout',
    'Maintain constant visual lookout, scanning horizon and water surface.',
    'eye',
  );
  add(
    watchId,
    'Engine Instruments',
    'Monitor engine gauges for normal operation and warning indicators.',
    'gauge',
  );
  add(
    watchId,
    'Navigation Lights',
    'Verify all required navigation lights are operating correctly.',
    'lib/assets/lists/AnualChecks/NavigationLights.jpg',
  );
  add(
    watchId,
    'Bilge Levels',
    'Check bilges periodically for water accumulation.',
    'lib/assets/lists/DailyEngineChecks/Bilge.jpg',
  );
  add(
    watchId,
    'Weather Conditions',
    'Monitor changing weather conditions and update forecasts as needed.',
    'lib/assets/lists/OneWeek/Weather.jpg',
  );
  add(
    watchId,
    'Wind Speed Trend',
    'Monitor wind speed every 15-30 min. A sustained increase of 6-8 knots in 3 hours or less often indicates approaching strong weather. Wake skipper if trend continues.',
    'lib/assets/lists/WatchChecks/WindSpeed.jpg',
  );
  add(
    watchId,
    'Wind Direction Shift',
    'Note any persistent wind shift that affects course or sail trim. Large veering or backing may indicate frontal passage or low-pressure system.',
    'lib/assets/lists/WatchChecks/WindDirection.jpg',
  );
  add(
    watchId,
    'Visibility',
    'Regularly assess visibility. Cross-check visual horizon distance against radar/AIS ranges. Reduced visibility (fog, rain squalls) requires immediate radar watch and sound signals.',
    'lib/assets/lists/WatchChecks/Visibility.jpg',
  );
  add(
    watchId,
    'Barometric Pressure Trend',
    'Log barometric pressure hourly. A fall of ≥7 mb in 3 hours is a strong indicator of deteriorating weather. Wake skipper immediately.',
    'lib/assets/lists/WatchChecks/BarometricPressure.jpg',
  );
  add(
    watchId,
    'Sea State',
    'Monitor wave height and period. Increasing sea state before wind rise often precedes a front. Consider reefing early if seas are building rapidly.',
    'lib/assets/lists/WatchChecks/SeaState.jpg',
  );
  add(
    watchId,
    'Weather Broadcasts & GRIB Updates',
    'When in range, listen for urgent marine warnings on VHF/SSB. Download latest GRIB files and routing at scheduled times. Compare forecast with observed conditions and wake skipper if significant deviation occurs.',
    'lib/assets/lists/OneWeek/Weather.jpg',
  );
  add(
    watchId,
    'Commercial Traffic & Collision Risk',
    'Maintain active radar and AIS watch. For any vessel on potential collision course, confirm CPA/TCPA. Never assume the other vessel has seen you or will give way, even if you are stand-on vessel.',
    'lib/assets/lists/WatchChecks/TrafficShips.jpg',
  );
  add(
    watchId,
    'Small Craft & Fishing Gear',
    'Especially near coastlines: scan for unlit fishing boats, marker buoys, longlines, or nets. Look for sudden changes in wave pattern or floating debris that may indicate unmarked hazards.',
    'lib/assets/lists/WatchChecks/TrafficSmallBoats.jpg',
  );

  await seedChecklistItemsToDrift(items);
}
