import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sisu_mate/core/di.dart';
import 'package:sisu_mate/data/drift/app_database.dart';
import 'package:sisu_mate/services/admob_platform.dart';
import 'package:sisu_mate/services/admob_service.dart';
import 'package:sisu_mate/services/free_edit_gate.dart';
import 'package:sisu_mate/services/revenuecat_service.dart';
import 'package:sisu_mate/services/sync_service.dart';
import 'package:sisu_mate/ui/components/banner_ad_widget.dart';
import 'package:sisu_mate/ui/onboarding/onboarding_screen.dart';

/// TEST11 — Free/Pro gate matrix (release-path confidence without RC SDK).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  void mockConnectivity(bool online) {
    const channel = MethodChannel('dev.fluttercommunity.plus/connectivity');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      if (call.method == 'check') {
        return <String>[online ? 'wifi' : 'none'];
      }
      return null;
    });
  }

  group('RM1 / RM2 debug-only (source contract)', () {
    final root = Directory.current.path;

    test('kForceProForTesting is gated by kDebugMode and not under FLUTTER_TEST',
        () {
      final src = File('$root/lib/services/revenuecat_service.dart')
          .readAsStringSync();
      expect(src, contains('kForceProForTesting'));
      expect(src, contains('kDebugMode'));
      expect(src, contains('FLUTTER_TEST'));
      // The bypass must require debug + not-test.
      expect(
        src.contains('kDebugMode') &&
            src.contains("Platform.environment.containsKey('FLUTTER_TEST')"),
        isTrue,
      );
    });

    test('kBypassOnboardingForTesting is gated by kDebugMode only', () {
      final src =
          File('$root/lib/ui/onboarding/onboarding_screen.dart').readAsStringSync();
      expect(src, contains('kBypassOnboardingForTesting'));
      expect(src, contains('kDebugMode && kBypassOnboardingForTesting'));
    });

    test('isPro is false in unit tests even when kForceProForTesting is true',
        () async {
      expect(kForceProForTesting, isTrue);
      RevenueCatService.debugProOverrideForTests = null;
      expect(await RevenueCatService().isPro(), isFalse);
    });

    test('debugProOverrideForTests forces Free and Pro under FLUTTER_TEST',
        () async {
      RevenueCatService.debugProOverrideForTests = false;
      expect(await RevenueCatService().isPro(), isFalse);
      RevenueCatService.debugProOverrideForTests = true;
      expect(await RevenueCatService().isPro(), isTrue);
      RevenueCatService.debugProOverrideForTests = null;
    });
  });

  group('Free cannot sync; Pro can queue', () {
    late AppDatabase db;
    late ProviderContainer container;
    late SyncService sync;

    setUp(() {
      mockConnectivity(false);
      db = AppDatabase.forTesting(NativeDatabase.memory());
      container = ProviderContainer(
        overrides: [appDatabaseProvider.overrideWithValue(db)],
      );
      sync = container.read(syncServiceProvider);
    });

    tearDown(() async {
      RevenueCatService.debugProOverrideForTests = null;
      container.dispose();
      await db.close();
    });

    test('Free: queueOutgoingChange is a no-op (nothing reaches outbox)',
        () async {
      RevenueCatService.debugProOverrideForTests = false;
      await sync.queueOutgoingChange('boats', {
        'supabaseId': 'b-free',
        'name': 'Should not queue',
        'lastModified': DateTime.now().toUtc().toIso8601String(),
      });
      expect(await sync.pendingQueueSize(), 0);
    });

    test('Pro: queueOutgoingChange offline lands in outbox', () async {
      RevenueCatService.debugProOverrideForTests = true;
      await sync.queueOutgoingChange('boats', {
        'supabaseId': 'b-pro',
        'name': 'Should queue',
        'lastModified': DateTime.now().toUtc().toIso8601String(),
      });
      expect(await sync.pendingQueueSize(), 1);
    });
  });

  group('Free edit teaser vs Pro unlimited', () {
    late AppDatabase db;
    late WidgetRef ref;

    Future<void> pump(WidgetTester tester, {required bool isPro}) async {
      db = AppDatabase.forTesting(NativeDatabase.memory());
      await db.into(db.userSettingsTable).insert(
            UserSettingsTableCompanion.insert(id: const Value(1)),
          );
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appDatabaseProvider.overrideWithValue(db),
            isProProvider.overrideWith((r) => Stream.value(isPro)),
          ],
          child: MaterialApp(
            home: Consumer(
              builder: (context, r, _) {
                ref = r;
                r.watch(isProProvider);
                return const SizedBox.shrink();
              },
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump();
    }

    tearDown(() async {
      await db.close();
    });

    testWidgets('Free locks after freeEditAllowance consumes', (tester) async {
      await pump(tester, isPro: false);
      for (var i = 0; i < FreeEditGate.freeEditAllowance; i++) {
        expect(await FreeEditGate.tryConsume(ref), isTrue);
      }
      expect(await FreeEditGate.tryConsume(ref), isFalse);
      expect(await FreeEditGate.remaining(ref), 0);
    });

    testWidgets('Pro never locks and remaining is null', (tester) async {
      await pump(tester, isPro: true);
      for (var i = 0; i < FreeEditGate.freeEditAllowance + 5; i++) {
        expect(await FreeEditGate.tryConsume(ref), isTrue);
      }
      expect(await FreeEditGate.remaining(ref), isNull);
    });
  });

  group('Ads: Free subject to daily cap; Pro banner collapses', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
      AdMobService.resetInitializedForTests();
    });

    test('Free interstitial daily cap blocks after max per day', () async {
      final service = AdMobService(platform: FakeAdMobPlatform());
      for (var i = 0; i < AdMobService.maxInterstitialAdsPerDay; i++) {
        expect(await service.canShowInterstitialAd(), isTrue);
        await service.recordInterstitialAdShown();
      }
      expect(await service.canShowInterstitialAd(), isFalse);
    });

    testWidgets('BannerAdWidget is zero-size for Pro', (tester) async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appDatabaseProvider.overrideWithValue(db),
            isProProvider.overrideWith((r) => Stream.value(true)),
          ],
          child: const MaterialApp(home: Scaffold(body: BannerAdWidget())),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      // Pro path returns SizedBox.shrink — no AdWidget / no tall banner.
      expect(find.byType(BannerAdWidget), findsOneWidget);
      final size = tester.getSize(find.byType(BannerAdWidget));
      expect(size.height, 0);
    });
  });

  group('Onboarding bypass constant still present for debug', () {
    test('kBypassOnboardingForTesting is true in source (debug-only use)', () {
      expect(kBypassOnboardingForTesting, isTrue);
    });
  });
}
