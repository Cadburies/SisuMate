import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// Provider for app package information
final packageInfoProvider = FutureProvider<PackageInfo>((ref) async {
  return PackageInfo.fromPlatform();
});

/// Provider for app version string (e.g., "1.0.0")
final appVersionProvider = FutureProvider<String>((ref) async {
  final packageInfo = await ref.watch(packageInfoProvider.future);
  return packageInfo.version;
});

/// Provider for app name and version combined (e.g., "Sisu Mate v1.0.0")
final appNameVersionProvider = FutureProvider<String>((ref) async {
  final packageInfo = await ref.watch(packageInfoProvider.future);
  return '${packageInfo.appName} v${packageInfo.version}';
});
