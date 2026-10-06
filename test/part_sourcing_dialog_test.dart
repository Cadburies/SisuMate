import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:sisu_mate/core/di.dart';
import 'package:sisu_mate/data/drift/app_database.dart';
import 'package:sisu_mate/models/models.dart';
import 'package:sisu_mate/services/location_service.dart';
import 'package:sisu_mate/services/revenuecat_service.dart';
import 'package:sisu_mate/ui/maintenance/part_sourcing_dialog.dart';

import 'test_helpers/platform_mocks.dart';

/// Injectable [LocationService] test double — returns whatever canned
/// [LocationResult] the test sets, no real GPS/platform channel involved.
class _FakeLocationService implements LocationService {
  final LocationResult result;
  const _FakeLocationService(this.result);

  @override
  Future<LocationResult> getCurrentPosition({
    LocationAccuracy accuracy = LocationAccuracy.medium,
    Duration timeLimit = const Duration(seconds: 12),
  }) async => result;
}

Position _fakePosition({double lat = 22.6273, double lon = 120.3014}) =>
    Position(
      latitude: lat,
      longitude: lon,
      timestamp: DateTime(2026, 1, 1),
      accuracy: 5.0,
      altitude: 0.0,
      altitudeAccuracy: 0.0,
      heading: 0.0,
      headingAccuracy: 0.0,
      speed: 0.0,
      speedAccuracy: 0.0,
    );

/// #217 (part sourcing) / #208: the AI badge's entry point is exercised in
/// `maintenance_ai_explainer_test.dart` (menu item presence); this file
/// drives the dialog itself — location resolution, coarse-location privacy,
/// and the no-key fallback (#18's pattern).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late AppDatabase db;

  setUp(() {
    mockConnectivityChannel();
    mockPathProviderChannel();
    mockSharedPreferencesChannel();
    db = AppDatabase.forTesting(NativeDatabase.memory());
    RevenueCatService.debugProOverrideForTests = false;
  });

  tearDown(() async {
    RevenueCatService.debugProOverrideForTests = null;
    await db.close();
  });

  Future<void> pumpDialog(
    WidgetTester tester, {
    required LocationService locationService,
    http.Client? geocodeHttpClient,
  }) async {
    await db
        .into(db.boats)
        .insert(
          BoatsCompanion.insert(
            supabaseId: const Value('boat_1'),
            name: const Value('Sisu'),
          ),
        );
    await db
        .into(db.userSettingsTable)
        .insert(
          UserSettingsTableCompanion.insert(
            id: const Value(1),
            activeBoatSupabaseId: const Value('boat_1'),
          ),
        );

    final item = ChecklistItem()
      ..supabaseId = 'maint_1'
      ..title = 'Change oil filter'
      ..description = 'Yanmar 3YM30';

    final container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        isProProvider.overrideWith((ref) => Stream.value(true)),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: Scaffold(
            body: PartSourcingDialog(
              item: item,
              locationService: locationService,
              geocodeHttpClient: geocodeHttpClient,
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
  }

  testWidgets('shows the disclaimer banner regardless of location outcome', (
    tester,
  ) async {
    await pumpDialog(
      tester,
      locationService: const _FakeLocationService(
        LocationResult.failure(LocationFailureReason.permissionDenied),
      ),
    );

    expect(find.textContaining('not a live parts catalog'), findsOneWidget);
  });

  testWidgets('permission denied falls back to a manual location field, not a '
      'blocked dead end', (tester) async {
    await pumpDialog(
      tester,
      locationService: const _FakeLocationService(
        LocationResult.failure(LocationFailureReason.permissionDenied),
      ),
    );

    expect(find.textContaining('Location permission denied'), findsOneWidget);
    expect(
      find.widgetWithText(TextField, 'Your city / region'),
      findsOneWidget,
    );
    expect(find.text('Search'), findsOneWidget);
    expect(find.text('Skip'), findsOneWidget);
  });

  testWidgets(
    'submitting a manual location names that area in the offline guide; '
    'Improve with AI shows the no-key message',
    (tester) async {
      await pumpDialog(
        tester,
        locationService: const _FakeLocationService(
          LocationResult.failure(LocationFailureReason.permissionDenied),
        ),
      );

      expect(find.textContaining('Offline part guide'), findsOneWidget);

      await tester.enterText(
        find.widgetWithText(TextField, 'Your city / region'),
        'Kaohsiung',
      );
      await tester.ensureVisible(find.text('Search'));
      await tester.tap(find.text('Search'));
      await tester.pump();

      expect(find.textContaining('Area: Kaohsiung'), findsOneWidget);
      expect(
        find.widgetWithText(TextField, 'Your city / region'),
        findsNothing,
      );
      expect(find.textContaining('No AI API key is configured'), findsNothing);

      await tester.tap(find.text('Improve with AI (online)'));
      await tester.pump();
      await tester.pump();

      expect(
        find.textContaining('No AI API key is configured'),
        findsOneWidget,
      );
      expect(find.text('Go to Settings'), findsOneWidget);
      expect(find.textContaining('Offline part guide'), findsOneWidget);
    },
  );

  testWidgets('"Skip" keeps the offline guide and does not call the AI', (
    tester,
  ) async {
    await pumpDialog(
      tester,
      locationService: const _FakeLocationService(
        LocationResult.failure(LocationFailureReason.permissionDenied),
      ),
    );

    await tester.ensureVisible(find.text('Skip'));
    await tester.tap(find.text('Skip'));
    await tester.pump();

    expect(find.textContaining('Offline part guide'), findsOneWidget);
    expect(find.textContaining('Area: not set'), findsOneWidget);
    expect(find.widgetWithText(TextField, 'Your city / region'), findsNothing);
    expect(find.textContaining('No AI API key is configured'), findsNothing);
  });

  testWidgets(
    'a resolved GPS fix reverse-geocodes to a coarse label on the offline '
    'guide, with no manual location field and no AI call',
    (tester) async {
      await pumpDialog(
        tester,
        locationService: _FakeLocationService(
          LocationResult.success(_fakePosition()),
        ),
        geocodeHttpClient: MockClient((request) async {
          return http.Response('{"display_name": "Kaohsiung, Taiwan"}', 200);
        }),
      );
      await tester.pump();

      expect(
        find.widgetWithText(TextField, 'Your city / region'),
        findsNothing,
      );
      expect(find.textContaining('Kaohsiung, Taiwan'), findsOneWidget);
      expect(find.textContaining('No AI API key is configured'), findsNothing);
      expect(find.text('Improve with AI (online)'), findsOneWidget);
    },
  );

  testWidgets(
    'a resolved GPS fix whose reverse-geocode fails falls back to manual '
    'entry rather than sending raw coordinates',
    (tester) async {
      await pumpDialog(
        tester,
        locationService: _FakeLocationService(
          LocationResult.success(_fakePosition()),
        ),
        geocodeHttpClient: MockClient((request) async {
          return http.Response('server error', 500);
        }),
      );
      await tester.pump();

      expect(
        find.textContaining('Could not resolve your area'),
        findsOneWidget,
      );
      expect(
        find.widgetWithText(TextField, 'Your city / region'),
        findsOneWidget,
      );
    },
  );
}
