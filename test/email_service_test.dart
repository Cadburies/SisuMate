import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sisu_mate/core/di.dart';
import 'package:sisu_mate/domain/repositories/user_settings_repository.dart';
import 'package:sisu_mate/models/models.dart';
import 'package:sisu_mate/services/email_service.dart';

class _FakeSettingsRepo implements UserSettingsRepository {
  _FakeSettingsRepo(this.settings);

  UserSettings settings;
  int updateCalls = 0;

  @override
  Future<UserSettings?> getSettings() async => settings;

  @override
  Stream<UserSettings?> watchSettings() => Stream.value(settings);

  @override
  Future<void> updateSettings(UserSettings s) async {
    updateCalls++;
    settings = s;
  }
}

void main() {
  tearDown(EmailService.resetDebugHooks);

  group('EmailService pure helpers', () {
    test('buildMailtoUri percent-encodes spaces (not +)', () {
      final uri = EmailService.buildMailtoUri(
        recipient: 'crew@example.com',
        subject: 'Shopping list',
        body: 'Buy fenders and line',
        replyTo: 'skipper@boat.com',
      );

      expect(uri.scheme, 'mailto');
      expect(uri.path, 'crew@example.com');
      final query = uri.query;
      expect(query, contains('subject=Shopping%20list'));
      expect(query, contains('body=Buy%20fenders%20and%20line'));
      expect(query, contains('reply-to=skipper%40boat.com'));
      expect(query, isNot(contains('+')));
    });

    test('buildMailtoUri omits empty reply-to', () {
      final uri = EmailService.buildMailtoUri(
        recipient: 'a@b.com',
        subject: 'S',
        body: 'B',
        replyTo: '   ',
      );
      expect(uri.query, isNot(contains('reply-to')));
    });

    test('nextRecentEmails is MRU and capped', () {
      expect(
        EmailService.nextRecentEmails(['a@x.com', 'b@x.com'], 'c@x.com', max: 5),
        ['c@x.com', 'a@x.com', 'b@x.com'],
      );
      // Moving an existing address to the front without duplicating.
      expect(
        EmailService.nextRecentEmails(['a@x.com', 'b@x.com'], 'b@x.com'),
        ['b@x.com', 'a@x.com'],
      );
      // Cap.
      final many = List.generate(6, (i) => '$i@x.com');
      final next = EmailService.nextRecentEmails(many, 'new@x.com', max: 5);
      expect(next, hasLength(5));
      expect(next.first, 'new@x.com');
    });
  });

  group('RecipientDialog', () {
    testWidgets('pre-fills the most recent email and Send returns it',
        (tester) async {
      String? result;
      await tester.pumpWidget(MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: ElevatedButton(
              onPressed: () async {
                result = await showDialog<String>(
                  context: context,
                  builder: (_) => const RecipientDialog(
                    recentEmails: ['first@boat.com', 'second@boat.com'],
                  ),
                );
              },
              child: const Text('Open'),
            ),
          ),
        ),
      ));

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text('first@boat.com'), findsWidgets);

      await tester.tap(find.text('Send'));
      await tester.pumpAndSettle();
      expect(result, 'first@boat.com');
    });

    testWidgets('chip replaces the field text', (tester) async {
      String? result;
      await tester.pumpWidget(MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: ElevatedButton(
              onPressed: () async {
                result = await showDialog<String>(
                  context: context,
                  builder: (_) => const RecipientDialog(
                    recentEmails: ['first@boat.com', 'second@boat.com'],
                  ),
                );
              },
              child: const Text('Open'),
            ),
          ),
        ),
      ));

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ActionChip, 'second@boat.com'));
      await tester.pump();
      await tester.tap(find.text('Send'));
      await tester.pumpAndSettle();
      expect(result, 'second@boat.com');
    });

    testWidgets('Cancel returns null', (tester) async {
      Object? result = 'sentinel';
      await tester.pumpWidget(MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: ElevatedButton(
              onPressed: () async {
                result = await showDialog<String>(
                  context: context,
                  builder: (_) =>
                      const RecipientDialog(recentEmails: ['a@b.com']),
                );
              },
              child: const Text('Open'),
            ),
          ),
        ),
      ));

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(result, isNull);
    });
  });

  group('EmailService.composeAndSend', () {
    testWidgets('launches mailto and records the recipient', (tester) async {
      final repo = _FakeSettingsRepo(UserSettings()
        ..recentEmails = ['old@boat.com']
        ..fromName = 'Skipper'
        ..replyToEmail = 'skipper@boat.com');
      Uri? launched;

      EmailService.debugLaunchUrl = (uri) async {
        launched = uri;
        return true;
      };

      final container = ProviderContainer(overrides: [
        userSettingsRepositoryProvider.overrideWithValue(repo),
        userSettingsProvider.overrideWith((ref) async => repo.settings),
      ]);
      addTearDown(container.dispose);

      await tester.pumpWidget(UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: Consumer(
            builder: (context, ref, _) => Scaffold(
              body: ElevatedButton(
                onPressed: () => EmailService.composeAndSend(
                  context,
                  ref,
                  subject: 'List',
                  body: 'Milk',
                ),
                child: const Text('Share'),
              ),
            ),
          ),
        ),
      ));

      await tester.tap(find.text('Share'));
      await tester.pumpAndSettle();
      // Pre-filled with most recent; change to a new address.
      await tester.enterText(find.byType(TextField), 'new@boat.com');
      await tester.tap(find.text('Send'));
      await tester.pumpAndSettle();

      expect(launched, isNotNull);
      expect(launched!.scheme, 'mailto');
      expect(launched!.path, 'new@boat.com');
      expect(launched!.query, contains('Milk'));
      expect(launched!.query, contains('%E2%80%94')); // em dash signature
      expect(repo.updateCalls, 1);
      expect(repo.settings.recentEmails.first, 'new@boat.com');
    });

    testWidgets('shows a snackbar when no mail app is available',
        (tester) async {
      final repo = _FakeSettingsRepo(UserSettings());
      EmailService.debugLaunchUrl = (_) async => false;

      final container = ProviderContainer(overrides: [
        userSettingsRepositoryProvider.overrideWithValue(repo),
        userSettingsProvider.overrideWith((ref) async => repo.settings),
      ]);
      addTearDown(container.dispose);

      await tester.pumpWidget(UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: Consumer(
            builder: (context, ref, _) => Scaffold(
              body: ElevatedButton(
                onPressed: () => EmailService.composeAndSend(
                  context,
                  ref,
                  subject: 'S',
                  body: 'B',
                ),
                child: const Text('Share'),
              ),
            ),
          ),
        ),
      ));

      await tester.tap(find.text('Share'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'x@y.com');
      await tester.tap(find.text('Send'));
      await tester.pumpAndSettle();

      expect(find.text('No email app available'), findsOneWidget);
      expect(repo.updateCalls, 0);
    });
  });
}
