import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../../models/models.dart';
import '../../providers/shopping_provider.dart';
import '../../core/di.dart';
import '../../core/colors.dart';

class StatusBar extends ConsumerStatefulWidget {
  const StatusBar({super.key});

  @override
  ConsumerState<StatusBar> createState() => _StatusBarState();
}

class _StatusBarState extends ConsumerState<StatusBar> {
  List<ConnectivityResult> _connectivity = [ConnectivityResult.none];

  @override
  void initState() {
    super.initState();
    _initConnectivity();
    Connectivity().onConnectivityChanged.listen(_updateConnectivity);
  }

  Future<void> _initConnectivity() async {
    try {
      final result = await Connectivity().checkConnectivity();
      _updateConnectivity(result);
    } catch (e) {
      // Failed to get connectivity: $e
    }
  }

  void _updateConnectivity(List<ConnectivityResult> result) {
    if (mounted) {
      setState(() => _connectivity = result);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isProAsync = ref.watch(isProProvider);
    final activeBoatAsync = ref.watch(activeBoatProvider);

    return isProAsync.when(
      data: (isPro) => activeBoatAsync.when(
        data: (boat) => _buildStatusBar(isPro, boat),
        loading: () => _buildStatusBar(isPro, null),
        error: (_, _) => _buildStatusBar(isPro, null),
      ),
      loading: () => activeBoatAsync.when(
        data: (boat) => _buildStatusBar(false, boat),
        loading: () => _buildStatusBar(false, null),
        error: (_, _) => _buildStatusBar(false, null),
      ),
      error: (_, _) => activeBoatAsync.when(
        data: (boat) => _buildStatusBar(false, boat),
        loading: () => _buildStatusBar(false, null),
        error: (_, _) => _buildStatusBar(false, null),
      ),
    );
  }

  Widget _buildStatusBar(bool isPro, Boat? activeBoat) {
    final isOnline = _connectivity.any((result) => result != ConnectivityResult.none);
    final backgroundColor = _getBackgroundColor(isPro, isOnline);
    final textColor = Theme.of(context).colorScheme.onPrimary;

    return Container(
      height: 44,
      color: backgroundColor,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          // Left: App name + Boat name per prd.md section 5
          Expanded(
            flex: 2,
            child: Text(
              activeBoat != null ? '${activeBoat.name} • Sisu' : 'Sisu Mate • Sisu',
              style: TextStyle(
                color: textColor,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),

          // Center: Pro/Free indicator
          Text(
            isPro ? 'Pro' : 'Free',
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),

          const SizedBox(width: 8),

          // Right: Online status + Time + Battery
          Expanded(
            child: Text(
              isOnline ? 'Online • 14:32 • 89%' : 'Offline • 14:32 • 89%',
              textAlign: TextAlign.right,
              style: TextStyle(
                color: textColor.withValues(alpha: 0.9),
                fontSize: 12,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  /// Get background color based on Pro status and connectivity
  Color _getBackgroundColor(bool isPro, bool isOnline) {
    return SisuColors.getStatusBarColor(isPro, isOnline);
  }
}
