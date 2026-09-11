import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/platform_capabilities.dart';
import '../ui/paywall/paywall_screen.dart';
import 'error_log_service.dart';

/// TESTING BYPASS — when true, `isPro()` always returns true after the real
/// entitlement check, so on-device testing runs as Pro without re-purchasing.
/// Only ever takes effect in debug builds (gated by [kDebugMode] at the use
/// site), so a release build is safe even if this is left `true`. Tracked in
/// outstanding.md (RM1).
const bool kForceProForTesting = true;

/// Tester-build Pro expiry. Empty in ordinary debug/release. Play internal /
/// TestFlight scripts inject `--dart-define=FORCE_PRO_UNTIL=2026-12-31T23:59:59Z`
/// so testers have full Pro for all of 2026. A production store build must omit
/// this define (compile-time empty → no-op). Never applies under `FLUTTER_TEST`.
/// Keep this ISO string in sync with `scripts/play_release.sh`,
/// `scripts/appstore_release.sh`, and `.ai_context/store_release.md`.
const String kForceProUntilRaw = String.fromEnvironment('FORCE_PRO_UNTIL');
const String kTesterProUntil = '2026-12-31T23:59:59Z';

/// Parses [kForceProUntilRaw] (or [raw] in tests). Null when unset/invalid.
DateTime? parseForceProUntil(String raw) {
  if (raw.trim().isEmpty) return null;
  return DateTime.tryParse(raw.trim())?.toUtc();
}

/// True when a tester-build [FORCE_PRO_UNTIL] dart-define is still in the
/// future. Always false under the test runner unless [underTest] is forced
/// false so the helper itself can be unit-tested.
bool isTesterProActive({
  String raw = kForceProUntilRaw,
  DateTime? now,
  bool? underTest,
}) {
  final inTest =
      underTest ?? Platform.environment.containsKey('FLUTTER_TEST');
  if (inTest) return false;
  final until = parseForceProUntil(raw);
  if (until == null) return false;
  return (now ?? DateTime.now().toUtc()).isBefore(until);
}

/// Title-bar token while a tester/debug grant is live (#348).
const String kTesterStatusLabel = 'Tester 2026';

/// Test-only seam so widget tests can force the Tester 2026 label / ads-off
/// path. Reset in `tearDown`. Never consulted outside `FLUTTER_TEST`.
@visibleForTesting
bool? debugTestModeOverrideForTests;

/// Tester IPA (`FORCE_PRO_UNTIL`) or debug `kForceProForTesting`. False under
/// the test runner unless [debugTestModeOverrideForTests] / [underTest] say
/// otherwise.
bool isTestModeActive({
  String raw = kForceProUntilRaw,
  DateTime? now,
  bool? underTest,
}) {
  if (Platform.environment.containsKey('FLUTTER_TEST') &&
      debugTestModeOverrideForTests != null) {
    return debugTestModeOverrideForTests!;
  }
  if (isTesterProActive(raw: raw, now: now, underTest: underTest)) {
    return true;
  }
  final inTest =
      underTest ?? Platform.environment.containsKey('FLUTTER_TEST');
  if (inTest) return false;
  return kDebugMode && kForceProForTesting;
}

/// Status-line Pro/Free token. Tester/debug grant reads [kTesterStatusLabel].
String statusTierLabel({required bool isPro, bool? testerMode}) {
  if (testerMode ?? isTestModeActive()) return kTesterStatusLabel;
  return isPro ? 'Pro' : 'Free';
}

/// Ads (banner / native / interstitial / reserved slots) stay off for Pro
/// *and* for the tester/debug grant.
bool hideAdsFor({required bool isPro, bool? testerMode}) =>
    isPro || (testerMode ?? isTestModeActive());

/// Debug bootstrap identity used together with [kForceProForTesting] so on-device
/// Pro testing runs against a fixed Supabase owner account + boat instead of the
/// full sign-up flow. Only consumed on debug (kDebugMode) code paths. The account
/// must exist in Supabase (create it via the app's sign-up or the dashboard).
const String kDebugAccountEmail = 'sailingsisu@outlook.com';
const String kDebugBoatName = 'Sisu';

class RevenueCatService {
  static final RevenueCatService instance = RevenueCatService._internal();
  factory RevenueCatService() => instance;
  RevenueCatService._internal();

  /// Test-only seam (TEST1b): unit tests can force `isPro()` without a real
  /// RevenueCat SDK, since this class's singleton constructor can't be
  /// subclassed/mocked. Only honored under the test runner (`FLUTTER_TEST`)
  /// — never reachable in a real app run. Reset in `tearDown`.
  @visibleForTesting
  static bool? debugProOverrideForTests;

  static const String _revenueCatApiKeyApple = 'appl_OjgmqPLiWRJqpajxKJYYWLAIRbC';
  static const String _revenueCatApiKeyGoogle = 'goog_zKnwHdfdiULvLWUklEEUzknqmdL';
  static const String _revenueCatApiKeyTest = 'test_jADOBAJlOvREoSGlypuRlEdOdyK';

  static const String entitlementId = 'Boat Checks Pro';
  static const String annualProductId = 'sisu_mate_pro_yearly'; // iOS: sisu_mate_pro_yearly | Android: proyearly:yearly
  static const String monthlyProductId =
      'sisu_mate_pro_monthly'; // iOS: sisu_mate_pro_monthly | Android: promonthly:promonthly

  static const String _prefsUserIdKey = 'revenuecat_user_id';

  CustomerInfo? _customerInfo;
  bool _isInitialized = false;
  bool _initFailed = false;
  bool _listenerAttached = false;

  /// Emits whenever cached [CustomerInfo] changes (purchase, restore, login).
  /// [isProProvider] listens so Free/Pro UI updates without a manual invalidate.
  final StreamController<void> _customerInfoUpdated =
      StreamController<void>.broadcast();

  Stream<void> get onCustomerInfoUpdated => _customerInfoUpdated.stream;

  Future<void> init() async {
    if (_isInitialized || _initFailed) return;
    if (!DeviceCapabilities.inAppPurchases) {
      _initFailed = true;
      return;
    }

    try {
      // await Purchases.setLogLevel(LogLevel.debug);

      if (kDebugMode) {
        await Purchases.configure(
          PurchasesConfiguration(_revenueCatApiKeyTest),
        );
      } else if (Platform.isAndroid) {
        await Purchases.configure(
          PurchasesConfiguration(_revenueCatApiKeyGoogle),
        );
      } else if (Platform.isIOS || Platform.isMacOS) {
        await Purchases.configure(
          PurchasesConfiguration(_revenueCatApiKeyApple),
        );
      }

      final appUserId = await _resolveAppUserId();
      await Purchases.logIn(appUserId);

      if (!_listenerAttached) {
        Purchases.addCustomerInfoUpdateListener((customerInfo) {
          _customerInfo = customerInfo;
          _notifyCustomerInfoUpdated();
        });
        _listenerAttached = true;
      }

      _customerInfo = await Purchases.getCustomerInfo();
      _isInitialized = true;
      _notifyCustomerInfoUpdated();
    } catch (e) {
      _initFailed = true; // Circuit-breaker: don't retry on every isPro() call
    }
  }

  /// Prefer Supabase auth id so Pro follows the account across devices;
  /// fall back to a stable anonymous id in SharedPreferences.
  Future<String> _resolveAppUserId() async {
    final prefs = await SharedPreferences.getInstance();
    final supabaseId = Supabase.instance.client.auth.currentUser?.id;
    if (supabaseId != null && supabaseId.isNotEmpty) {
      await prefs.setString(_prefsUserIdKey, supabaseId);
      return supabaseId;
    }
    var userId = prefs.getString(_prefsUserIdKey) ?? '';
    if (userId.isEmpty) {
      userId = 'user_${DateTime.now().millisecondsSinceEpoch}';
      await prefs.setString(_prefsUserIdKey, userId);
    }
    return userId;
  }

  /// PRO3: identify RevenueCat with the Supabase user (or return to anonymous).
  ///
  /// Call on auth state changes. [supabaseUserId] null/empty → [Purchases.logOut]
  /// then a device-local anonymous id.
  Future<void> linkSupabaseUserId(String? supabaseUserId) async {
    if (!_isInitialized && !_initFailed) await init();
    if (_initFailed) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final target = (supabaseUserId != null && supabaseUserId.isNotEmpty)
          ? supabaseUserId
          : null;

      if (target != null) {
        final result = await Purchases.logIn(target);
        _customerInfo = result.customerInfo;
        await prefs.setString(_prefsUserIdKey, target);
      } else {
        // Drop identified session; store a fresh anonymous app user id.
        try {
          _customerInfo = await Purchases.logOut();
        } catch (_) {
          // Already anonymous or SDK error — still mint local id.
        }
        final anon = 'user_${DateTime.now().millisecondsSinceEpoch}';
        await prefs.setString(_prefsUserIdKey, anon);
        try {
          final result = await Purchases.logIn(anon);
          _customerInfo = result.customerInfo;
        } catch (_) {
          // ignore
        }
      }
      _notifyCustomerInfoUpdated();
    } catch (e) {
      // Platform channel missing in tests / offline — keep last known state.
      unawaited(ErrorLogService().logWarning(
        'RevenueCat linkSupabaseUserId failed: $e',
        context: 'revenuecat_service: linkSupabaseUserId',
      ));
    }
  }

  void updateCustomerInfo(CustomerInfo info) {
    _customerInfo = info;
    _notifyCustomerInfoUpdated();
  }

  void _notifyCustomerInfoUpdated() {
    if (!_customerInfoUpdated.isClosed) {
      _customerInfoUpdated.add(null);
    }
  }

  /// Real entitlement expiration (null when not subscribed). The debug
  /// [kForceProForTesting] bypass is deliberately NOT reflected here — the
  /// profiles heartbeat (STALE-DATA) must record the true subscription state.
  /// Tester-build [kForceProUntilRaw] *is* returned so TestFlight Pro grants
  /// stamp the compiled expiry (end of 2026 for the current tester wave).
  Future<DateTime?> proExpiresAt() async {
    if (isTesterProActive()) {
      return parseForceProUntil(kForceProUntilRaw);
    }
    if (!_isInitialized && !_initFailed) await init();
    final s = _customerInfo?.entitlements.active[entitlementId]?.expirationDate;
    return s != null ? DateTime.tryParse(s) : null;
  }

  Future<bool> isPro() async {
    if (Platform.environment.containsKey('FLUTTER_TEST') &&
        debugProOverrideForTests != null) {
      return debugProOverrideForTests!;
    }
    // Tester IPA/APK compiled with FORCE_PRO_UNTIL — release-safe because
    // the define is empty unless that build flag is passed. Never in tests.
    if (isTesterProActive()) {
      return true;
    }
    if (!_isInitialized && !_initFailed) await init();
    final entitlements = _customerInfo?.entitlements.active ?? {};
    final realIsPro = entitlements.containsKey(entitlementId);
    // TESTING BYPASS (outstanding.md RM1). Debug builds only, so it can never
    // reach a release build. Runtime only: never in unit tests, which rely on
    // the real (Free) result.
    if (kDebugMode &&
        kForceProForTesting &&
        !Platform.environment.containsKey('FLUTTER_TEST')) {
      return true;
    }
    return realIsPro;
  }

  Future<void> showPaywall(BuildContext context) async {
    if (!DeviceCapabilities.inAppPurchases) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Subscriptions are not available on this device.'),
          ),
        );
      }
      return;
    }
    try {
      final result = await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => const PaywallScreen(),
        ),
      );

      // Result will be true if purchase was successful
      if (result == true) {
        // Refresh customer info
        _customerInfo = await Purchases.getCustomerInfo();
        _notifyCustomerInfoUpdated();
      }
    } catch (e) {
      // User cancelled or error occurred
    }
  }

  Future<void> restorePurchases() async {
    try {
      final customerInfo = await Purchases.restorePurchases();
      _customerInfo = customerInfo;
      _notifyCustomerInfoUpdated();
    } catch (e) {
      // ignore
    }
  }
}
