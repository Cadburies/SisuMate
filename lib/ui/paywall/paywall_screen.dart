import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show PlatformException;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import '../components/title_tile.dart';
import '../../core/app_router.dart';
import '../../core/supabase_client.dart';
import '../../services/error_log_service.dart';
import '../../services/revenuecat_service.dart';
import '../../core/di.dart';

class PaywallScreen extends ConsumerStatefulWidget {
  const PaywallScreen({super.key});

  @override
  ConsumerState<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends ConsumerState<PaywallScreen> {
  List<Package> _packages = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadPackages();
  }

  Future<void> _loadPackages() async {
    try {
      final offerings = await Purchases.getOfferings();
      final currentOffering = offerings.current;

      if (currentOffering != null) {
        setState(() {
          _packages = currentOffering.availablePackages
              .where((p) =>
                  p.packageType == PackageType.monthly ||
                  p.packageType == PackageType.annual)
              .toList();
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = 'No subscription packages available';
          _isLoading = false;
        });
      }
    } catch (e, st) {
      unawaited(
          ErrorLogService().logException(e, st, context: 'paywall_screen: load offerings'));
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  /// Purchase/restore user-cancellation is expected control flow — the
  /// RevenueCat SDK surfaces it as a typed [PurchasesErrorCode], not a
  /// generic failure, so it can be filtered out precisely instead of
  /// guessing from the message text.
  static bool _isUserCancelled(Object e) =>
      e is PlatformException &&
      PurchasesErrorHelper.getErrorCode(e) ==
          PurchasesErrorCode.purchaseCancelledError;

  Future<void> _purchasePackage(Package package) async {
    setState(() => _isLoading = true);

    try {
      final result = await Purchases.purchase(PurchaseParams.package(package));
      final customerInfo = result.customerInfo;

      if (customerInfo.entitlements.active.containsKey(RevenueCatService.entitlementId)) {
        // Push fresh customer info into the service cache before invalidating.
        RevenueCatService().updateCustomerInfo(customerInfo);
        if (mounted) {
          ref.invalidate(isProProvider);
          Navigator.of(context).pop(true);
          _showSuccessDialog();
        }
      }
    } catch (e, st) {
      if (!_isUserCancelled(e)) {
        unawaited(
            ErrorLogService().logException(e, st, context: 'paywall_screen: purchase'));
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Purchase failed: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _restorePurchases() async {
    setState(() => _isLoading = true);

    try {
      final customerInfo = await Purchases.restorePurchases();

      if (customerInfo.entitlements.active.containsKey(RevenueCatService.entitlementId)) {
        RevenueCatService().updateCustomerInfo(customerInfo);
        if (mounted) {
          ref.invalidate(isProProvider);
          Navigator.of(context).pop(true);
          _showSuccessDialog();
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No previous purchases found')),
          );
        }
      }
    } catch (e, st) {
      if (!_isUserCancelled(e)) {
        unawaited(
            ErrorLogService().logException(e, st, context: 'paywall_screen: restore'));
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Restore failed: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('🎉 Welcome to Sisu Mate Pro!'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 48),
            SizedBox(height: 16),
            Text(
              'You now have access to all Pro features:\n\n'
              '• Mark items complete & add notes\n'
              '• Unlimited history & photos\n'
              '• Real-time crew sync\n'
              '• Multiple boats\n'
              '• No ads',
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(dialogCtx).pop();
              // Point 2: upgrade leads into creating the boat account (unless a
              // session already exists, e.g. the debug bootstrap owner).
              if (mounted &&
                  SupabaseClientWrapper.instance.auth.currentUser == null) {
                context.push(AppRoutes.accountSetup);
              }
            },
            child: const Text('Get Started'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const TitleTile(title: 'Upgrade to Sisu Mate Pro'),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _error != null
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.error, size: 48, color: Colors.red),
                                const SizedBox(height: 16),
                                Text(_error!, textAlign: TextAlign.center),
                                const SizedBox(height: 16),
                                ElevatedButton(
                                  onPressed: _loadPackages,
                                  child: const Text('Retry'),
                                ),
                              ],
                            ),
                          )
                        : SingleChildScrollView(
                            child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Header
                              const Icon(
                                Icons.directions_boat,
                                size: 64,
                                color: Color(0xFF2E8B57),
                              ),
                              const SizedBox(height: 24),
                              const Text(
                                'Unlock the Full Power of Sisu Mate',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'Professional offshore boating management with unlimited features',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 32),

                              // Features
                              const Text(
                                'Pro Features:',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 16),
                              _buildFeatureItem('Mark items complete & add notes'),
                              _buildFeatureItem('Unlimited history & photos'),
                              _buildFeatureItem('Real-time crew sync'),
                              _buildFeatureItem('Multiple boats'),
                              _buildFeatureItem('No ads'),
                              const SizedBox(height: 32),

                              // Subscription Options
                              if (_packages.isNotEmpty) ...[
                                const Text(
                                  'Choose Your Plan:',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                ..._packages.map((package) => _buildPackageButton(package)),
                              ],

                              const SizedBox(height: 32),

                              // Restore Purchases
                              TextButton(
                                onPressed: _restorePurchases,
                                child: const Text('Restore Previous Purchase'),
                              ),
                              const SizedBox(height: 8),

                              // Terms
                              const Text(
                                'Subscriptions auto-renew. Cancel anytime in App Store settings.',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 16),
                            ],
                          ),
                          ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureItem(String feature) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          const Icon(Icons.check, color: Colors.green, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              feature,
              style: const TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPackageButton(Package package) {
    final isYearly = package.packageType == PackageType.annual;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: ElevatedButton(
        onPressed: () => _purchasePackage(package),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          backgroundColor: isYearly ? const Color(0xFF2E8B57) : Colors.blue,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Column(
          children: [
            Text(
              isYearly ? 'Yearly Plan' : 'Monthly Plan',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              package.storeProduct.priceString,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (isYearly) ...[
              const SizedBox(height: 4),
              const Text(
                '2 months free!',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w300),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
