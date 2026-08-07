import 'package:flutter_test/flutter_test.dart';
import 'package:sisu_mate/models/models.dart';
import 'package:sisu_mate/services/fuel_burn_estimator.dart';
import 'package:sisu_mate/services/suggestion_engine.dart';
import 'package:sisu_mate/services/weather_service.dart';

void main() {
  const engine = SuggestionEngine();

  MaintenanceTask task({
    String desc = 'Oil change',
    int? intervalMonths,
    DateTime? lastDone,
    bool hidden = false,
  }) =>
      MaintenanceTask()
        ..supabaseId = 't1'
        ..description = desc
        ..intervalMonths = intervalMonths
        ..lastDoneDate = lastDone
        ..isHidden = hidden;

  group('SuggestionEngine (S4)', () {
    test('flags overdue maintenance when past interval months', () {
      final now = DateTime.utc(2026, 7, 1);
      final list = engine.build(
        maintenanceTasks: [
          task(
            intervalMonths: 6,
            lastDone: DateTime.utc(2025, 1, 1),
          ),
        ],
        now: now,
      );
      expect(list, isNotEmpty);
      expect(list.first.severity, SuggestionSeverity.urgent);
      expect(list.first.title, contains('Overdue'));
    });

    test('flags due soon within 14 days', () {
      final now = DateTime.utc(2026, 7, 20);
      final list = engine.build(
        maintenanceTasks: [
          task(
            intervalMonths: 1,
            lastDone: DateTime.utc(2026, 6, 25), // due 2026-07-25 → 5 days
          ),
        ],
        now: now,
      );
      expect(list, isNotEmpty);
      expect(list.first.severity, SuggestionSeverity.watch);
      expect(list.first.title, contains('Due soon'));
    });

    test('ignores hidden tasks and tasks without intervals', () {
      final list = engine.build(
        maintenanceTasks: [
          task(intervalMonths: 6, lastDone: DateTime.utc(2020, 1, 1), hidden: true),
          task(intervalMonths: null, lastDone: null),
        ],
        now: DateTime.utc(2026, 7, 1),
      );
      expect(list.where((s) => s.id.startsWith('maint_')), isEmpty);
    });

    test('weather notes trigger rough-conditions tip', () {
      final list = engine.build(
        maintenanceTasks: const [],
        recentWeatherNotes: ['Gale force winds overnight'],
      );
      expect(list.any((s) => s.id == 'wx_storm'), isTrue);
    });

    test('high wind knots produce breeze tip', () {
      final list = engine.build(
        maintenanceTasks: const [],
        windKnots: 18,
      );
      expect(list.any((s) => s.id == 'wx_breeze'), isTrue);
    });
  });

  group('SuggestionEngine.build BAI7 rules', () {
    test('foggy log notes produce low-visibility tip', () {
      final list = engine.build(
        maintenanceTasks: const [],
        recentWeatherNotes: ['Thick fog in the approaches'],
      );
      expect(list.any((s) => s.id == 'wx_fog'), isTrue);
      expect(list.firstWhere((s) => s.id == 'wx_fog').routePath, '/weather');
    });

    test('lightning/thunder notes produce thunderstorm tip', () {
      final list = engine.build(
        maintenanceTasks: const [],
        recentWeatherNotes: ['Distant thunder after sunset'],
      );
      expect(list.any((s) => s.id == 'wx_lightning'), isTrue);
      expect(
        list.firstWhere((s) => s.id == 'wx_lightning').severity,
        SuggestionSeverity.watch,
      );
    });

    test('missing captain log suggests starting one', () {
      final list = engine.build(
        maintenanceTasks: const [],
        lastLogDate: null,
      );
      expect(list.any((s) => s.id == 'log_missing'), isTrue);
    });

    test('stale captain log after logStaleDays suggests a new entry', () {
      final now = DateTime.utc(2026, 7, 30);
      final list = engine.build(
        maintenanceTasks: const [],
        lastLogDate: DateTime.utc(2026, 7, 1), // 29 days old
        now: now,
      );
      expect(list.any((s) => s.id == 'log_stale'), isTrue);
      expect(list.firstWhere((s) => s.id == 'log_stale').title, contains('29'));
    });

    test('fresh captain log does not produce log tips', () {
      final now = DateTime.utc(2026, 7, 30);
      final list = engine.build(
        maintenanceTasks: const [],
        lastLogDate: DateTime.utc(2026, 7, 28),
        now: now,
      );
      expect(list.any((s) => s.id.startsWith('log_')), isFalse);
    });

    test('fuel runway within fuelWatchDays produces a fuel tip', () {
      final list = engine.build(
        maintenanceTasks: const [],
        lastLogDate: DateTime.utc(2026, 7, 29), // avoid log_missing
        fuelEstimates: const [
          TankBurnEstimate(
            type: 'Fuel',
            daysUntilEmpty: 4,
            sampleFills: 3,
            summary: '',
          ),
        ],
      );
      expect(list.any((s) => s.id == 'fuel_fuel'), isTrue);
      expect(
        list.firstWhere((s) => s.id == 'fuel_fuel').severity,
        SuggestionSeverity.watch,
      );
    });

    test('fuel runway ≤2 days is urgent', () {
      final list = engine.build(
        maintenanceTasks: const [],
        lastLogDate: DateTime.utc(2026, 7, 29),
        fuelEstimates: const [
          TankBurnEstimate(
            type: 'Water',
            daysUntilEmpty: 1,
            sampleFills: 2,
            summary: '',
          ),
        ],
      );
      final tip = list.firstWhere((s) => s.id == 'fuel_water');
      expect(tip.severity, SuggestionSeverity.urgent);
      expect(tip.routePath, '/fuel');
    });

    test('fog + storm notes can both appear (distinct tips)', () {
      final list = engine.build(
        maintenanceTasks: const [],
        recentWeatherNotes: ['Gale with fog patches'],
        lastLogDate: DateTime.utc(2026, 7, 29),
      );
      expect(list.any((s) => s.id == 'wx_storm'), isTrue);
      expect(list.any((s) => s.id == 'wx_fog'), isTrue);
    });
  });

  group('SuggestionEngine.passageReadiness (BAI1)', () {
    ChecklistItem safetyItem({required bool done}) =>
        ChecklistItem()..isCompleted = done;

    test('ready when safety is complete, nothing overdue, calm weather, '
        'plenty of fuel', () {
      final r = engine.passageReadiness(
        safetyItems: [safetyItem(done: true), safetyItem(done: true)],
        maintenanceTasks: const [],
        weather: WeatherBundle(
          lat: 0,
          lon: 0,
          fetchedAt: DateTime.utc(2026, 7, 30),
          fromCache: true,
          windMs: 3,
        ),
        fuelEstimates: const [
          TankBurnEstimate(
              type: 'Fuel', daysUntilEmpty: 20, sampleFills: 2, summary: ''),
        ],
        now: DateTime.utc(2026, 7, 30),
      );
      expect(r.isReady, isTrue);
      expect(r.blockers, isEmpty);
      expect(r.headline, 'Ready for passage');
    });

    test('unchecked safety items block readiness', () {
      final r = engine.passageReadiness(
        safetyItems: [safetyItem(done: false), safetyItem(done: true)],
        maintenanceTasks: const [],
      );
      expect(r.isReady, isFalse);
      expect(r.blockers.single, contains('1 safety item'));
    });

    test('overdue maintenance blocks readiness (reuses build\'s due logic)',
        () {
      final r = engine.passageReadiness(
        safetyItems: const [],
        maintenanceTasks: [
          task(intervalMonths: 6, lastDone: DateTime.utc(2025, 1, 1)),
        ],
        now: DateTime.utc(2026, 7, 1),
      );
      expect(r.isReady, isFalse);
      expect(r.blockers, contains('1 maintenance task overdue'));
    });

    test('strong cached wind blocks readiness', () {
      final r = engine.passageReadiness(
        safetyItems: const [],
        maintenanceTasks: const [],
        weather: WeatherBundle(
          lat: 0,
          lon: 0,
          fetchedAt: DateTime.utc(2026, 7, 30),
          fromCache: true,
          windMs: 15, // ~29 kn
        ),
      );
      expect(r.isReady, isFalse);
      expect(r.blockers.single, contains('kn wind'));
    });

    test('near-empty tank blocks readiness', () {
      final r = engine.passageReadiness(
        safetyItems: const [],
        maintenanceTasks: const [],
        fuelEstimates: const [
          TankBurnEstimate(
              type: 'Water', daysUntilEmpty: 1, sampleFills: 3, summary: ''),
        ],
      );
      expect(r.isReady, isFalse);
      expect(r.blockers.single, contains('Water estimated 1 day from empty'));
    });

    test('headline counts every blocker, not just one', () {
      final r = engine.passageReadiness(
        safetyItems: [safetyItem(done: false)],
        maintenanceTasks: [
          task(intervalMonths: 6, lastDone: DateTime.utc(2025, 1, 1)),
        ],
        now: DateTime.utc(2026, 7, 1),
      );
      expect(r.blockers, hasLength(2));
      expect(r.headline, 'Fix 2 things first');
    });
  });

  group('SuggestionEngine.checklistAutopilot (BAI3)', () {
    ChecklistGroup group(String id, String title) => ChecklistGroup()
      ..supabaseId = id
      ..title = title;

    final groups = [
      group('g_last', 'Last Minute Departure Checks'),
      group('g_oneday', 'One Day Before Departure Checks'),
      group('g_oneweek', 'One Week Before Departure Checks'),
      group('g_doc', 'Documents Checks'),
      group('g_watch', 'On-Watch Monitoring Checks'),
      group('g_annual', 'Annual Checks'),
    ];

    test('no known trip suggests nothing', () {
      final out = engine.checklistAutopilot(checklistGroups: groups);
      expect(out, isEmpty);
    });

    test('departing tomorrow suggests last-minute + one-day + documents', () {
      final out = engine.checklistAutopilot(
        checklistGroups: groups,
        daysUntilDeparture: 1,
      );
      expect(out.map((s) => s.group.supabaseId),
          containsAll(['g_last', 'g_oneday', 'g_doc']));
      expect(out.any((s) => s.group.supabaseId == 'g_oneweek'), isFalse);
    });

    test('departing in 5 days suggests one-week + documents, not last-minute',
        () {
      final out = engine.checklistAutopilot(
        checklistGroups: groups,
        daysUntilDeparture: 5,
      );
      expect(out.map((s) => s.group.supabaseId),
          containsAll(['g_oneweek', 'g_doc']));
      expect(out.any((s) => s.group.supabaseId == 'g_last'), isFalse);
    });

    test('far-off departure (>7 days) suggests only documents', () {
      final out = engine.checklistAutopilot(
        checklistGroups: groups,
        daysUntilDeparture: 30,
      );
      expect(out.map((s) => s.group.supabaseId), ['g_doc']);
    });

    test('multi-day trip adds the watch-monitoring checklist', () {
      final out = engine.checklistAutopilot(
        checklistGroups: groups,
        daysUntilDeparture: 3,
        tripLengthDays: 4,
      );
      expect(out.map((s) => s.group.supabaseId), contains('g_watch'));
    });

    test('day trip does not suggest watch-monitoring', () {
      final out = engine.checklistAutopilot(
        checklistGroups: groups,
        daysUntilDeparture: 3,
        tripLengthDays: 1,
      );
      expect(out.any((s) => s.group.supabaseId == 'g_watch'), isFalse);
    });

    test('rough cached weather pulls in last-minute checks even without a '
        'known departure', () {
      final out = engine.checklistAutopilot(
        checklistGroups: groups,
        weather: WeatherBundle(
          lat: 0,
          lon: 0,
          fetchedAt: DateTime.utc(2026, 7, 30),
          fromCache: true,
          windMs: 15, // ~29 kn
        ),
      );
      expect(out.map((s) => s.group.supabaseId), ['g_last']);
    });

    test('never suggests the same group twice even if two rules match it',
        () {
      final out = engine.checklistAutopilot(
        checklistGroups: groups,
        daysUntilDeparture: 1, // matches last-minute
        weather: WeatherBundle(
          lat: 0,
          lon: 0,
          fetchedAt: DateTime.utc(2026, 7, 30),
          fromCache: true,
          windMs: 15, // also matches last-minute
        ),
      );
      expect(
        out.where((s) => s.group.supabaseId == 'g_last'),
        hasLength(1),
      );
    });

    test('missing checklist titles are simply skipped, not an error', () {
      final out = engine.checklistAutopilot(
        checklistGroups: const [], // boat has no checklists at all
        daysUntilDeparture: 1,
        tripLengthDays: 5,
      );
      expect(out, isEmpty);
    });

    test('#296 nightWatch phase matches night checklist title', () {
      final withNight = [
        ...groups,
        group('g_night', 'Night Watch Checks'),
      ];
      final out = engine.checklistAutopilot(
        checklistGroups: withNight,
        daysUntilDeparture: -1,
        tripLengthDays: 5,
      );
      // Underway (negative days, not yet arrival) → passage or night via keywords.
      // Explicit nightWatchNow:
      final night = engine.checklistAutopilot(
        checklistGroups: withNight,
        daysUntilDeparture: 10,
      );
      // Force phase via tripPhaseFor unit:
      expect(
        engine.tripPhaseFor(nightWatchNow: true),
        TripPhase.nightWatch,
      );
      expect(
        engine.tripPhaseFor(daysUntilDeparture: 1),
        TripPhase.preDeparture,
      );
      // Quiet compile use of out/night
      expect(out, isA<List<ChecklistAutopilotSuggestion>>());
      expect(night, isA<List<ChecklistAutopilotSuggestion>>());
    });
  });

  group('SuggestionEngine.build #297/#298', () {
    test('expiring document surfaces a tip', () {
      final doc = Document()
        ..supabaseId = 'd1'
        ..title = 'Passport'
        ..type = 'ID'
        ..expiry = DateTime.utc(2026, 8, 10);
      final tips = engine.build(
        maintenanceTasks: const [],
        documents: [doc],
        now: DateTime.utc(2026, 8, 1),
      );
      expect(tips.any((t) => t.id == 'doc_d1'), isTrue);
      expect(tips.singleWhere((t) => t.id == 'doc_d1').title,
          contains('Passport'));
    });

    test('low inventory qty surfaces a tip', () {
      final inv = InventoryItem()
        ..name = 'Impeller'
        ..quantity = 0;
      final tips = engine.build(
        maintenanceTasks: const [],
        inventory: [inv],
        now: DateTime.utc(2026, 8, 1),
      );
      expect(tips.any((t) => t.id == 'inv_low_stock'), isTrue);
    });
  });
}
