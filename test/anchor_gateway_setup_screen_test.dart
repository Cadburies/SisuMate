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

/// #263 — Anchor Alarm gateway setup: DataHub + YDWG-02 fields, Discover,
/// Test, Save to [UserSettings]. In-memory Drift + MockClient.
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
    // Tall surface: DataHub + YDWG + HA cards + Save below the fold.
    await tester.binding.setSurfaceSize(const Size(400, 2400));
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

  Future<void> reveal(WidgetTester tester, Finder finder) async {
    await tester.scrollUntilVisible(
      finder,
      300.0,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.ensureVisible(finder);
    await tester.pump();
  }

  testWidgets(
      'starts with DataHub remote + YDWG example defaults',
      (tester) async {
    await pumpScreen(tester);

    expect(find.text('Gateway Setup'), findsOneWidget);
    expect(find.text('Found:'), findsNothing);
    expect(find.text('Default for DataHub'), findsOneWidget);
    expect(find.widgetWithText(ActionChip, 'DataHub internet'), findsOneWidget);
    expect(find.widgetWithText(ActionChip, 'DataHub local'), findsOneWidget);
    expect(find.text('YDWG-02 (NMEA gateway)'), findsOneWidget);

    final addressField = find.widgetWithText(TextField, 'Hub address');
    await reveal(tester, addressField);
    expect(
      tester.widget<TextField>(addressField).controller!.text,
      PredictWindDatahubService.defaultDataHubRemoteUrlResolved,
    );

    final ydwgField = find.widgetWithText(TextField, 'YDWG address');
    await reveal(tester, ydwgField);
    expect(
      tester.widget<TextField>(ydwgField).controller!.text,
      PredictWindDatahubService.defaultYdwgUrl,
    );
    expect(
      tester
          .widget<TextField>(find.widgetWithText(TextField, 'YDWG username'))
          .controller!
          .text,
      PredictWindDatahubService.defaultYdwgUsernameResolved,
    );
  });

  testWidgets('DataHub local chip fills Hub address only', (tester) async {
    await pumpScreen(tester);

    final localChip = find.widgetWithText(ActionChip, 'DataHub local');
    await reveal(tester, localChip);
    await tester.tap(localChip);
    await tester.pumpAndSettle();

    final addressField = find.widgetWithText(TextField, 'Hub address');
    expect(
      tester.widget<TextField>(addressField).controller!.text,
      PredictWindDatahubService.defaultDataHubLocalUrl,
    );
    // YDWG field unchanged (own section).
    expect(
      tester
          .widget<TextField>(find.widgetWithText(TextField, 'YDWG address'))
          .controller!
          .text,
      PredictWindDatahubService.defaultYdwgUrl,
    );
  });

  testWidgets('Save persists DataHub and YDWG credentials separately',
      (tester) async {
    await pumpScreen(tester);

    await tester.enterText(
        find.widgetWithText(TextField, 'DataHub username'), 'boatuser');
    await tester.enterText(
        find.widgetWithText(TextField, 'DataHub password'), 'boatpass');
    final ipField = find.widgetWithText(TextField, 'Hub address');
    await reveal(tester, ipField);
    await tester.enterText(ipField, 'http://remote.rdsensing.com:36121');

    final ydwgUrl = find.widgetWithText(TextField, 'YDWG address');
    await reveal(tester, ydwgUrl);
    await tester.enterText(ydwgUrl, 'http://192.168.10.30');
    await tester.enterText(
        find.widgetWithText(TextField, 'YDWG username'), 'admin');
    await tester.enterText(
        find.widgetWithText(TextField, 'YDWG password'), 'admin');

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
    expect(saved.ydwgUrl, 'http://192.168.10.30');
    expect(saved.ydwgUsername, 'admin');
    expect(saved.ydwgPassword, 'admin');
    expect(find.textContaining('YDWG-02'), findsWidgets);
  });

  testWidgets('Discover finds a working remote tunnel and selects it',
      (tester) async {
    final client = MockClient((request) async {
      if (request.url.host == 'remote.rdsensing.com' &&
          request.url.port == 36121) {
        return loginOk();
      }
      throw Exception('connection refused');
    });
    await pumpScreen(tester, httpClient: client);

    await tester.enterText(
        find.widgetWithText(TextField, 'DataHub username'), 'u');
    await tester.enterText(
        find.widgetWithText(TextField, 'DataHub password'), 'p');
    await tester.tap(find.widgetWithText(ElevatedButton, 'Discover DataHub'));
    await tester.pumpAndSettle();

    expect(find.text('Found:'), findsOneWidget);
    expect(
      find.widgetWithText(
          RadioListTile<String>, 'http://remote.rdsensing.com:36121'),
      findsOneWidget,
    );
    expect(find.textContaining('Internet'), findsWidgets);
  });

  testWidgets('Discover with nothing reachable shows a helpful summary',
      (tester) async {
    final client = MockClient((request) async {
      throw Exception('connection refused');
    });
    await pumpScreen(tester, httpClient: client);

    await tester.enterText(
        find.widgetWithText(TextField, 'DataHub username'), 'u');
    await tester.enterText(
        find.widgetWithText(TextField, 'DataHub password'), 'p');
    await tester.tap(find.widgetWithText(ElevatedButton, 'Discover DataHub'));
    await tester.pumpAndSettle();

    expect(find.text('Found:'), findsNothing);
    final message = find.textContaining('No gateway answered');
    await reveal(tester, message);
    expect(message, findsOneWidget);
  });

  testWidgets('DataHub Test succeeds and reports connected', (tester) async {
    final client = MockClient((request) async => loginOk());
    await pumpScreen(tester, httpClient: client);

    await tester.enterText(
        find.widgetWithText(TextField, 'DataHub username'), 'u');
    await tester.enterText(
        find.widgetWithText(TextField, 'DataHub password'), 'p');
    final ipField = find.widgetWithText(TextField, 'Hub address');
    await reveal(tester, ipField);
    await tester.enterText(ipField, '10.10.10.5');
    final testButton = find.widgetWithText(OutlinedButton, 'Test DataHub');
    await reveal(tester, testButton);
    await tester.tap(testButton);
    await tester.pumpAndSettle();

    final message = find.textContaining('Connected to DataHub');
    await reveal(tester, message);
    expect(message, findsOneWidget);
  });

  testWidgets('DataHub Test failure shows a clear error, not a crash',
      (tester) async {
    final client = MockClient((request) async => http.Response('', 403));
    await pumpScreen(tester, httpClient: client);

    await tester.enterText(
        find.widgetWithText(TextField, 'DataHub username'), 'u');
    await tester.enterText(
        find.widgetWithText(TextField, 'DataHub password'), 'wrong');
    final ipField = find.widgetWithText(TextField, 'Hub address');
    await reveal(tester, ipField);
    await tester.enterText(ipField, '10.10.10.5');
    final testButton = find.widgetWithText(OutlinedButton, 'Test DataHub');
    await reveal(tester, testButton);
    await tester.tap(testButton);
    await tester.pumpAndSettle();

    final message = find.textContaining("Couldn't connect");
    await reveal(tester, message);
    expect(message, findsOneWidget);
  });

  testWidgets('YDWG Test login uses web /login and reports success',
      (tester) async {
    final client = MockClient((request) async {
      if (request.method == 'POST' && request.url.path == '/login') {
        return http.Response(
          '',
          204,
          headers: {'set-cookie': 'session=abc; path=/'},
        );
      }
      throw Exception('unexpected ${request.method} ${request.url}');
    });
    await pumpScreen(tester, httpClient: client);

    final testYdwg =
        find.widgetWithText(OutlinedButton, 'Test YDWG login');
    await reveal(tester, testYdwg);
    await tester.tap(testYdwg);
    await tester.pumpAndSettle();

    final message = find.textContaining('Signed in to YDWG');
    await reveal(tester, message);
    expect(message, findsOneWidget);
    expect(find.textContaining('tap Save to keep'), findsOneWidget);
  });

  testWidgets('loads previously saved DataHub + YDWG settings',
      (tester) async {
    final repo = container.read(userSettingsRepositoryProvider);
    final settings = UserSettings()
      ..predictwindHubUsername = 'existing'
      ..predictwindHubPassword = 'secret'
      ..predictwindHubLocalUrl = 'http://remote.rdsensing.com:36121'
      ..ydwgUrl = 'http://192.168.10.99'
      ..ydwgUsername = 'ydwguser'
      ..ydwgPassword = 'ydwgpass';
    await repo.updateSettings(settings);

    await pumpScreen(tester);

    String textOf(Finder finder) =>
        tester.widget<TextField>(finder).controller!.text;

    expect(
      textOf(find.widgetWithText(TextField, 'DataHub username')),
      'existing',
    );

    final ipField = find.widgetWithText(TextField, 'Hub address');
    await reveal(tester, ipField);
    expect(textOf(ipField), 'http://remote.rdsensing.com:36121');

    final ydwgField = find.widgetWithText(TextField, 'YDWG address');
    await reveal(tester, ydwgField);
    expect(textOf(ydwgField), 'http://192.168.10.99');
    expect(
      textOf(find.widgetWithText(TextField, 'YDWG username')),
      'ydwguser',
    );
  });
}
