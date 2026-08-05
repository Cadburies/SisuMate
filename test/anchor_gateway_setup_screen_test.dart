import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:sisu_mate/core/di.dart';
import 'package:sisu_mate/data/drift/app_database.dart';
import 'package:sisu_mate/models/models.dart';
import 'package:sisu_mate/services/predictwind_datahub_service.dart';
import 'package:sisu_mate/ui/anchor/anchor_gateway_setup_screen.dart';

/// #263 — Anchor Alarm gateway setup/onboarding screen: username/password,
/// "Discover" against [PredictWindDatahubService.knownLocalAddresses],
/// manual IP:port "Test", and "Save" persisting to [UserSettings]. In-memory
/// Drift DB (overriding `appDatabaseProvider`), and `httpClient` (mirroring
/// `AnchorAlarmScreen`'s seam) fakes the network — nothing touches real
/// on-disk state or a real host.
///
/// The screen's content is taller than the default test viewport, and its
/// `ListView` (like any Sliver-backed list) doesn't build children outside
/// the viewport + cache extent — so `find` can't see them, and `tap`/
/// `enterText` fail on lower cards, until scrolled there via
/// [scrollUntilVisible].
void main() {
  late AppDatabase db;
  late ProviderContainer container;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    container = ProviderContainer(overrides: [
      appDatabaseProvider.overrideWithValue(db),
    ]);
  });

  tearDown(() async {
    container.dispose();
    await db.close();
  });

  http.Response loginOk() => http.Response('', 302,
      headers: {'set-cookie': 'sysauth=abc123; path=/cgi-bin/luci/'});

  Future<void> pumpScreen(
    WidgetTester tester, {
    http.Client? httpClient,
  }) async {
    // Tall surface so Discover + manual + Save fit without fighting
    // ListView cache-extent / hit-test misses on the lower buttons.
    await tester.binding.setSurfaceSize(const Size(400, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: AnchorGatewaySetupScreen(httpClient: httpClient),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  // The screen has several Scrollables (the ListView, plus one inside each
  // single-line TextField for horizontal overflow) — `scrollUntilVisible`'s
  // default `find.byType(Scrollable)` isn't unique, so it's pinned to the
  // first one in the tree, which is the outer ListView's own (an ancestor
  // of every nested TextField, so it's always visited first in the
  // top-down element traversal `find.byType` walks).
  Future<void> reveal(WidgetTester tester, Finder finder) async {
    await tester.scrollUntilVisible(
      finder,
      300.0,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.ensureVisible(finder);
    await tester.pump();
  }

  testWidgets('starts with empty fields and no discovery results',
      (tester) async {
    await pumpScreen(tester);

    expect(find.text('Gateway Setup'), findsOneWidget);
    expect(find.text('Found:'), findsNothing);
  });

  testWidgets('Discover finds a working remote tunnel and selects it',
      (tester) async {
    // Only the vendor HTTP remote answers — simulates beach-bar internet.
    final client = MockClient((request) async {
      if (request.url.host == 'remote.rdsensing.com' &&
          request.url.port == 36121) {
        return loginOk();
      }
      throw Exception('connection refused');
    });
    await pumpScreen(tester, httpClient: client);

    await tester.enterText(find.widgetWithText(TextField, 'Username'), 'u');
    await tester.enterText(find.widgetWithText(TextField, 'Password'), 'p');
    await tester.tap(find.widgetWithText(ElevatedButton, 'Discover'));
    await tester.pumpAndSettle();

    expect(find.text('Found:'), findsOneWidget);
    expect(
      find.widgetWithText(
          RadioListTile<String>, 'http://remote.rdsensing.com:36121'),
      findsOneWidget,
    );
    // Subtitle on the radio + summary card both mention internet.
    expect(find.textContaining('Internet'), findsWidgets);
  });

  testWidgets('Discover with nothing reachable shows a helpful summary',
      (tester) async {
    final client = MockClient((request) async {
      throw Exception('connection refused');
    });
    await pumpScreen(tester, httpClient: client);

    await tester.enterText(find.widgetWithText(TextField, 'Username'), 'u');
    await tester.enterText(find.widgetWithText(TextField, 'Password'), 'p');
    await tester.tap(find.widgetWithText(ElevatedButton, 'Discover'));
    await tester.pumpAndSettle();

    expect(find.text('Found:'), findsNothing);
    final message = find.textContaining('No gateway answered');
    await reveal(tester, message);
    expect(message, findsOneWidget);
  });

  testWidgets('manual Test succeeds and reports the address as connected',
      (tester) async {
    final client = MockClient((request) async => loginOk());
    await pumpScreen(tester, httpClient: client);

    await tester.enterText(find.widgetWithText(TextField, 'Username'), 'u');
    await tester.enterText(find.widgetWithText(TextField, 'Password'), 'p');
    final ipField = find.widgetWithText(TextField, 'Hub address');
    await reveal(tester, ipField);
    await tester.enterText(ipField, '10.10.10.5');
    final testButton = find.widgetWithText(OutlinedButton, 'Test');
    await reveal(tester, testButton);
    await tester.tap(testButton);
    await tester.pumpAndSettle();

    final message = find.textContaining('Connected at');
    await reveal(tester, message);
    expect(message, findsOneWidget);
  });

  testWidgets('manual Test failure shows a clear error, not a crash',
      (tester) async {
    final client = MockClient((request) async => http.Response('', 403));
    await pumpScreen(tester, httpClient: client);

    await tester.enterText(find.widgetWithText(TextField, 'Username'), 'u');
    await tester.enterText(find.widgetWithText(TextField, 'Password'), 'wrong');
    final ipField = find.widgetWithText(TextField, 'Hub address');
    await reveal(tester, ipField);
    await tester.enterText(ipField, '10.10.10.5');
    final testButton = find.widgetWithText(OutlinedButton, 'Test');
    await reveal(tester, testButton);
    await tester.tap(testButton);
    await tester.pumpAndSettle();

    final message = find.textContaining("Couldn't connect");
    await reveal(tester, message);
    expect(message, findsOneWidget);
  });

  testWidgets(
      'Save persists a typed remote URL even without a prior Test',
      (tester) async {
    await pumpScreen(tester);

    await tester.enterText(
        find.widgetWithText(TextField, 'Username'), 'boatuser');
    await tester.enterText(
        find.widgetWithText(TextField, 'Password'), 'boatpass');
    final ipField = find.widgetWithText(TextField, 'Hub address');
    await reveal(tester, ipField);
    await tester.enterText(ipField, 'http://remote.rdsensing.com:36121');

    final saveButton = find.widgetWithText(ElevatedButton, 'Save');
    await reveal(tester, saveButton);
    await tester.tap(saveButton);
    await tester.pumpAndSettle();

    final repo = container.read(userSettingsRepositoryProvider);
    final saved = await repo.getSettings();
    expect(saved, isNotNull);
    expect(saved!.predictwindHubUsername, 'boatuser');
    expect(saved.predictwindHubPassword, 'boatpass');
    expect(saved.predictwindHubLocalUrl, 'http://remote.rdsensing.com:36121');
    expect(find.textContaining('internet remote access'), findsOneWidget);
  });

  testWidgets('loads previously saved settings into the fields',
      (tester) async {
    final repo = container.read(userSettingsRepositoryProvider);
    final settings = UserSettings()
      ..predictwindHubUsername = 'existing'
      ..predictwindHubPassword = 'secret'
      ..predictwindHubLocalUrl = 'http://remote.rdsensing.com:36121';
    await repo.updateSettings(settings);

    await pumpScreen(tester);

    String textOf(Finder finder) =>
        tester.widget<TextField>(finder).controller!.text;

    expect(textOf(find.widgetWithText(TextField, 'Username')), 'existing');

    final ipField = find.widgetWithText(TextField, 'Hub address');
    await reveal(tester, ipField);
    expect(textOf(ipField), 'http://remote.rdsensing.com:36121');
  });
}
