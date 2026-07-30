import 'dart:io';
import 'package:flutter/material.dart';
import '../../services/image_fallback_service.dart';

/// Offline-first image widget.
///
/// Priority (by design — no network):
/// 1. [userPhotoPath] — photo in app documents (camera/gallery)
/// 2. [assetName] — bundled asset under `assets/`
/// 3. Icon / [customFallback] / checklist [ImageFallbackService]
///
/// [userPhotoUrl] is only used when it is a **local file path** (legacy field
/// name). Remote `http(s)://` URLs are ignored so the app stays offline-capable.
class SmartImage extends StatelessWidget {
  /// Bundled asset path relative to `assets/`, or a legacy `assets/...` /
  /// `lib/assets/...` form, or a bare Material icon key for checklists.
  final String? assetName;

  /// Legacy field: local file path only (not a network URL).
  final String? userPhotoUrl;

  /// Preferred local file path (app documents / camera).
  final String? userPhotoPath;
  final String? itemName;
  final String? groupName;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget? customFallback;

  const SmartImage({
    super.key,
    this.assetName,
    this.userPhotoUrl,
    this.userPhotoPath,
    this.itemName,
    this.groupName,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.customFallback,
  });

  static bool _isRemoteUrl(String s) {
    final t = s.trim().toLowerCase();
    return t.startsWith('http://') || t.startsWith('https://');
  }

  static bool _looksLikeAssetPath(String s) {
    final t = s.trim();
    if (t.isEmpty || _isRemoteUrl(t)) return false;
    // Checklist icon keys are short tokens without a path separator or extension.
    if (!t.contains('/') && !t.contains('.') && !t.startsWith('assets')) {
      return false; // icon name
    }
    return true;
  }

  static String? _normalizeAssetPath(String raw) {
    var t = raw.trim();
    if (t.isEmpty) return null;
    if (t.startsWith('lib/assets/')) {
      t = t.substring('lib/assets/'.length);
    }
    if (t.startsWith('assets/')) {
      t = t.substring('assets/'.length);
    }
    return t.isEmpty ? null : t;
  }

  @override
  Widget build(BuildContext context) {
    // 1) Local file (user photo) — wins so camera shots override seed art.
    final local = _firstLocalPath();
    if (local != null) {
      return Image.file(
        File(local),
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (context, error, stackTrace) => _buildAssetOrIcon(),
      );
    }

    // 2) Bundled asset
    return _buildAssetOrIcon();
  }

  String? _firstLocalPath() {
    for (final p in [userPhotoPath, userPhotoUrl]) {
      if (p == null || p.trim().isEmpty) continue;
      if (_isRemoteUrl(p)) continue; // offline-first: ignore network
      if (_looksLikeAssetPath(p) && !p.startsWith('/')) {
        // Relative asset-like path stored in photo field — treat as asset, not file.
        continue;
      }
      return p;
    }
    return null;
  }

  Widget _buildAssetOrIcon() {
    if (assetName != null && assetName!.isNotEmpty) {
      if (!_looksLikeAssetPath(assetName!)) {
        // Bare icon name (checklist marine icons).
        final iconData = _getIconData(assetName!);
        return Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            iconData,
            size: 48,
            color: Colors.grey.shade700,
          ),
        );
      }

      final relative = _normalizeAssetPath(assetName!);
      if (relative != null) {
        return Image.asset(
          'assets/$relative',
          width: width,
          height: height,
          fit: fit,
          errorBuilder: (context, error, stackTrace) => _getFallbackWidget(),
        );
      }
    }
    return _getFallbackWidget();
  }

  IconData _getIconData(String iconName) {
    switch (iconName) {
      case 'hand-wave':
        return Icons.waving_hand;
      case 'ship':
        return Icons.directions_boat;
      case 'briefcase':
        return Icons.work;
      case 'droplet':
        return Icons.water_drop;
      case 'sun':
        return Icons.wb_sunny;
      case 'toilet':
        return Icons.wc;
      case 'faucet':
        return Icons.tap_and_play;
      case 'shower':
        return Icons.shower;
      case 'life-ring':
        return Icons.pool;
      case 'medkit':
        return Icons.medical_services;
      case 'compass':
        return Icons.explore;
      case 'shield-alert':
        return Icons.warning;
      case 'eye':
        return Icons.visibility;
      case 'flame':
        return Icons.local_fire_department;
      case 'chef-hat':
        return Icons.restaurant;
      case 'zap':
        return Icons.flash_on;
      case 'fire-extinguisher':
        return Icons.fire_extinguisher;
      case 'users':
        return Icons.group;
      case 'anchor':
        return Icons.anchor;
      case 'clock':
        return Icons.access_time;
      case 'cloud-rain':
        return Icons.grain;
      case 'radio':
        return Icons.radio;
      case 'steering-wheel':
        return Icons.settings;
      case 'shield':
        return Icons.security;
      case 'alert-triangle':
        return Icons.warning;
      case 'cloud':
        return Icons.cloud;
      case 'map':
        return Icons.map;
      case 'message-circle':
        return Icons.chat;
      case 'heart':
        return Icons.favorite;
      case 'user-minus':
        return Icons.person_remove;
      case 'waves':
        return Icons.waves;
      case 'radar':
        return Icons.track_changes;
      case 'gauge':
        return Icons.speed;
      case 'binoculars':
        return Icons.visibility;
      case 'ac-unit':
        return Icons.ac_unit;
      case 'autopilot':
        return Icons.settings_remote;
      case 'battery':
        return Icons.battery_charging_full;
      case 'belt':
        return Icons.settings_backup_restore;
      case 'cable':
      case 'rigging':
        return Icons.cable;
      case 'captain-license':
        return Icons.card_membership;
      case 'coolant':
        return Icons.thermostat;
      case 'cylinder':
        return Icons.engineering;
      case 'electrical':
      case 'zincs':
        return Icons.electrical_services;
      case 'engine':
        return Icons.settings;
      case 'engine-valves':
        return Icons.settings_input_composite;
      case 'exhaust':
        return Icons.air;
      case 'filter':
      case 'water-filter':
        return Icons.filter_alt;
      case 'fishing':
        return Icons.water;
      case 'fuel':
      case 'injector':
        return Icons.local_gas_station;
      case 'hardware':
      case 'mounting':
        return Icons.hardware;
      case 'heat-exchanger':
        return Icons.device_thermostat;
      case 'hull':
        return Icons.directions_boat;
      case 'impeller':
      case 'piston':
      case 'winch':
        return Icons.rotate_right;
      case 'keel':
        return Icons.anchor;
      case 'kitchen':
      case 'refrigerator':
        return Icons.kitchen;
      case 'masthead':
        return Icons.vertical_align_top;
      case 'no-drinks':
        return Icons.no_drinks;
      case 'oil':
        return Icons.opacity;
      case 'outboard':
      case 'turbo':
        return Icons.speed;
      case 'pets':
        return Icons.pets;
      case 'plumbing':
      case 'seacocks':
        return Icons.plumbing;
      case 'pool':
        return Icons.pool;
      case 'propane':
      case 'stove':
        return Icons.local_fire_department;
      case 'sail':
        return Icons.sailing;
      case 'spreaders':
        return Icons.open_with;
      case 'tiller':
        return Icons.tune;
      case 'water-heater':
        return Icons.hot_tub;
      case 'water-pump':
        return Icons.water_drop;
      case 'watermaker':
        return Icons.water;
      case 'watermaker-chart':
        return Icons.show_chart;
      case 'zarpe':
        return Icons.assignment_turned_in;
      case 'local_bar':
      case 'cocktail':
        return Icons.local_bar;
      default:
        return Icons.help;
    }
  }

  Widget _getFallbackWidget() {
    if (customFallback != null) {
      return customFallback!;
    }

    final fallbackAsset =
        ImageFallbackService.getFallbackAsset(itemName, groupName);

    return Image.asset(
      'assets/$fallbackAsset',
      width: width,
      height: height,
      fit: fit,
      errorBuilder: (context, error, stackTrace) => _getDefaultFallback(),
    );
  }

  Widget _getDefaultFallback() {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey.shade300,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        Icons.local_bar,
        color: Colors.grey.shade600,
        size: 28,
      ),
    );
  }
}
