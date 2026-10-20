import 'dart:async';

import 'package:bonsoir/bonsoir.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sisu_mate/services/lan/lan_engine.dart';
import 'package:sisu_mate/services/lan/lan_providers.dart';
import 'package:sisu_mate/ui/games/lobby/lobby_screen.dart';

import 'test_helpers/fake_lan_engine.dart';

/// #435: the host lobby shows the join code; a joining player must type it,
/// a wrong code sends them back with a clear message, and the last code is
/// pre-filled so a player whose app died mid-game can rejoin.
class _LobbyFakeEngine extends FakeLanEngine {
  final services = StreamController<List<BonsoirService>>.broadcast();
  final denied = StreamController<void>.broadcast();
  final codesUsed = <String>[];

  @override
  String? get accessCode => '123456';

  @override
  Stream<List<BonsoirService>> get discoveredServices => services.stream;

  @override
  Stream<void> get accessDenied => denied.stream;

  @override
  Future<void> startDiscovery() async {}

  @override
  Future<void> connectToService(BonsoirService service,
      {required String accessCode}) async {
    codesUsed.add(accessCode);
  }
}

void main() {
  late _LobbyFakeEngine engine;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    engine = _LobbyFakeEngine();
  });

  Future<void> pumpLobby(WidgetTester tester) async {
    await tester.pumpWidget(ProviderScope(
      overrides: [lanEngineProvider.overrideWithValue(engine as LanEngine)],
      child: const MaterialApp(
        home: GameLobbyScreen(gameId: 'liars_dice', gameName: "Liar's Dice"),
      ),
    ));
    await tester.enterText(find.byType(TextField), 'Frik');
  }

  Future<void> openJoinDialog(WidgetTester tester) async {
    await tester.tap(find.text('Join a Game'));
    await tester.pumpAndSettle();
    engine.services.add([
      BonsoirService(name: 'Skipper dice', type: '_sisumate._tcp', port: 1),
    ]);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Skipper dice'));
    await tester.pumpAndSettle();
  }

  testWidgets('host lobby shows the join code', (tester) async {
    await pumpLobby(tester);
    await tester.tap(find.text('Host Game'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('lobby-access-code')), findsOneWidget);
    expect(find.text('123 456'), findsOneWidget);
  });

  testWidgets('joining asks for the code and sends it', (tester) async {
    await pumpLobby(tester);
    await openJoinDialog(tester);
    expect(find.text('Join code'), findsOneWidget);

    await tester.enterText(find.byType(TextField).last, '654321');
    await tester.tap(find.widgetWithText(FilledButton, 'Join'));
    // Waiting view spins forever; pump instead of settling.
    await tester.pump(const Duration(milliseconds: 500));
    expect(engine.codesUsed, ['654321']);
  });

  testWidgets('cancelling the code dialog does not connect', (tester) async {
    await pumpLobby(tester);
    await openJoinDialog(tester);
    await tester.tap(find.descendant(
        of: find.byType(AlertDialog), matching: find.text('Cancel')));
    await tester.pumpAndSettle();
    expect(engine.codesUsed, isEmpty);
  });

  testWidgets('wrong code returns to the start with a message', (tester) async {
    await pumpLobby(tester);
    await openJoinDialog(tester);
    await tester.enterText(find.byType(TextField).last, '000000');
    await tester.tap(find.widgetWithText(FilledButton, 'Join'));
    // Waiting view spins forever; pump instead of settling.
    await tester.pump(const Duration(milliseconds: 500));

    engine.denied.add(null);
    await tester.pumpAndSettle();
    expect(find.textContaining('Wrong join code'), findsOneWidget);
    expect(find.text('Host Game'), findsOneWidget);
  });

  testWidgets('last used code is pre-filled for a rejoin', (tester) async {
    SharedPreferences.setMockInitialValues({'lan_last_join_code': '777888'});
    await pumpLobby(tester);
    await openJoinDialog(tester);
    expect(find.text('777888'), findsOneWidget);
    final field = tester.widget<TextField>(find.byType(TextField).last);
    expect(field.controller!.selection,
        const TextSelection(baseOffset: 0, extentOffset: 6),
        reason: 'typing a new code must replace the remembered one');
  });
}
