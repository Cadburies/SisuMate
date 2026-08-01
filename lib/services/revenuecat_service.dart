import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../ui/paywall/paywall_screen.dart';
import 'error_log_service.dart';

/// TESTING BYPASS — when true, `isPro()` always returns true after the real
/// entitlement check, so on-device testing runs as Pro without re-purchasing.
/// Only ever takes effect in debug builds (gated by [kDebugMode] at the use
/// site), so a release build is safe even if this is left `true`. Tracked in
/// outstanding.md (RM1).
const bool kForceProForTesting = true;

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

  /// Real entitlement expiration (null when not subscribed). Deliberately NOT
  /// covered by the testing bypass — the profiles heartbeat (STALE-DATA) must
  /// record the true subscription state, never the debug fiction.
  Future<DateTime?> proExpiresAt() async {
    if (!_isInitialized && !_initFailed) await init();
    final s = _customerInfo?.entitlements.active[entitlementId]?.expirationDate;
    return s != null ? DateTime.tryParse(s) : null;
  }

  Future<bool> isPro() async {
    if (Platform.environment.containsKey('FLUTTER_TEST') &&
        debugProOverrideForTests != null) {
      return debugProOverrideForTests!;
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
