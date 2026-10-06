import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sisu_mate/providers/package_info_provider.dart';
import 'package:sisu_mate/services/bundled_licenses.dart';
import 'package:sisu_mate/ui/components/common_drawer.dart';

/// #410 / #416: legal links open the real Pages URLs, the About dialog points
/// at them, and the licence page carries the bundled third-party credits.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Host tests have no registered url_launcher implementation, so the
  // platform interface falls back to this method channel.
  const channel = MethodChannel('plugins.flutter.io/url_launcher');
  final launched = <String>[];
  var launchResult = true;

  setUp(() {
    launched.clear();
    launchResult = true;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      if (call.method == 'launch') {
        launched.add((call.arguments as Map)['url'] as String);
        return launchResult;
      }
      return true;
    });
  });
  tearDown(() => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(channel, null));

  Future<void> pump(WidgetTester tester, Widget child) async {
    await tester.binding.setSurfaceSize(const Size(800, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(ProviderScope(
      overrides: [appVersionProvider.overrideWith((ref) async => '9.9.9')],
      child: MaterialApp(home: Scaffold(body: ListView(children: [child]))),
    ));
    await tester.pumpAndSettle();
  }

  group('LegalSection (#410)', () {
    testWidgets('each link opens its published page', (tester) async {
      await pump(tester, const LegalSection());
      final expected = {
        'Privacy Policy': 'https://cadburies.github.io/sisumate-legal/privacy-policy.html',
        'Terms of Use': 'https://cadburies.github.io/sisumate-legal/terms.html',
        'Support': 'https://cadburies.github.io/sisumate-legal/support.html',
        'Delete account (web)': 'https://cadburies.github.io/sisumate-legal/delete-account.html',
      };
      for (final e in expected.entries) {
        await tester.tap(find.text(e.key));
        await tester.pumpAndSettle();
        expect(launched.last, e.value, reason: e.key);
      }
      expect(launched, hasLength(4));
    });

    testWidgets('a link that cannot open says so instead of failing silently',
        (tester) async {
      launchResult = false;
      await pump(tester, const LegalSection());
      await tester.tap(find.text('Terms of Use'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Could not open'), findsOneWidget);
    });

    testWidgets('Open-source licences opens the licence page', (tester) async {
      await pump(tester, const LegalSection());
      await tester.tap(find.text('Open-source licences'));
      await tester.pumpAndSettle();
      expect(find.byType(LicensePage), findsOneWidget);
    });
  });

  group('About dialog (#410/#416)', () {
    testWidgets('shows licence line, Privacy opens the policy, Licences opens the page',
        (tester) async {
      await pump(tester, const AboutSection());
      await tester.tap(find.text('About'));
      await tester.pumpAndSettle();
      expect(find.text('Version: 9.9.9'), findsOneWidget);
      expect(find.text(LegalLinks.legalese), findsOneWidget);
      expect(find.text('Privacy Policy & Terms available in Settings.'), findsNothing);

      await tester.tap(find.widgetWithText(TextButton, 'Privacy'));
      await tester.pumpAndSettle();
      expect(launched, [LegalLinks.privacy]);

      await tester.tap(find.widgetWithText(TextButton, 'Licences'));
      await tester.pumpAndSettle();
      expect(find.byType(LicensePage), findsOneWidget);
    });
  });

  group('BundledLicenses (#416)', () {
    test('lists the font licence and the cocktail photo credits', () async {
      final entries = await BundledLicenses.entries().toList();
      String textOf(String package) {
        final e = entries.firstWhere((e) => e.packages.contains(package));
        return e.paragraphs.map((p) => p.text).join('\n');
      }

      final font = textOf('Noto Sans Runic');
      expect(font, contains('SIL OPEN FONT LICENSE Version 1.1'));
      expect(font, contains('The Noto Project Authors'));

      final photos = textOf('Sisu Mate cocktail photos');
      expect(photos, contains('Arnaud 25, CC BY-SA 4.0'));
      expect(photos, contains('Evan Swigart'));
      expect(photos, contains('CC BY 2.0'));
    });

    test('register() adds the entries to the LicenseRegistry once', () async {
      BundledLicenses.register();
      BundledLicenses.register();
      final all = await LicenseRegistry.licenses.toList();
      final runic = all.where((e) => e.packages.contains('Noto Sans Runic'));
      expect(runic, hasLength(1));
    });
  });
}
