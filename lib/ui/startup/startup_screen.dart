import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/app_router.dart';
import '../../core/colors.dart';
import '../../core/di.dart';
import '../../services/database_service.dart';
import '../../services/debug_bootstrap.dart';
import '../../services/profile_heartbeat.dart';
import '../../core/theme.dart';
import '../../core/units.dart';
import '../onboarding/onboarding_screen.dart' show hasSeenOnboarding;

class StartupScreen extends ConsumerStatefulWidget {
  const StartupScreen({super.key});

  @override
  ConsumerState<StartupScreen> createState() => _StartupScreenState();
}

class _StartupScreenState extends ConsumerState<StartupScreen> {
  @override
  void initState() {
    super.initState();
    // RT1: paint the splash once before opening Drift / seeding.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(_initialize());
    });
  }

  Future<void> _initialize() async {
    final result = await DatabaseService().init();
    if (!mounted) return;

    switch (result) {
      case DbInitResult.healthy:
      case DbInitResult.seeded:
        // Restore persisted theme + unit preference (no write-back).
        final settings = await ref.read(userSettingsProvider.future);
        if (!mounted) return;
        ref
            .read(themeModeProvider.notifier)
            .restoreTheme(settings?.isDarkMode ?? true);
        ref
            .read(unitPrefsProvider.notifier)
            .restoreFromJson(settings?.unitPrefsJson);

        // Capture the app-global container before navigating away — the widget
        // ref is unsafe once StartupScreen unmounts during the deferred work.
        final container = ProviderScope.containerOf(context, listen: false);
        // Navigate ASAP; heavy catalog seeds + sync start after home is up.
        await _goHome();
        if (!mounted) return;
        unawaited(_afterHomeReady(container));
      case DbInitResult.corrupted:
        _showCorruptionDialog();
    }
  }

  /// Expansion packs, bar/pantry patches, and SyncService (RT1).
  Future<void> _afterHomeReady(ProviderContainer container) async {
    unawaited(DatabaseService().runDeferredSeeds());
    // Debug-only: owner sign-in + active "Sisu" boat before sync starts.
    await DebugBootstrap.run(container);
    // STALE-DATA: record last-seen + real subscription state on the profile.
    unawaited(ProfileHeartbeat.stamp());
    // Touch the provider so Pro realtime/outbox starts without blocking UI.
    container.read(syncServiceProvider);
  }

  Future<void> _goHome() async {
    final seen = await hasSeenOnboarding();
    if (!mounted) return;
    context.go(seen ? AppRoutes.home : AppRoutes.onboarding);
  }

  void _showCorruptionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Database Problem'),
        content: const Text(
          'The local database is corrupted or incompatible with this '
          'version of Sisu Mate.\n\n'
          'Resetting will restore all bundled content (checklists, '
          'maintenance schedules, recipes). Any custom data you added '
          'will be lost.',
        ),
        actions: [
          TextButton(
            style: TextButton.styleFrom(
              // Destructive text button: notAvailableText reads on the dark
              // dialog surface, notAvailableBackground on the light one —
              // the single red tone doesn't clear WCAG AA against both.
              foregroundColor: Theme.of(ctx).brightness == Brightness.dark
                  ? SisuColors.notAvailableText
                  : SisuColors.notAvailableBackground,
            ),
            onPressed: () async {
              Navigator.of(ctx).pop();
              final resetResult = await DatabaseService().hardReset();
              if (!mounted) return;
              if (resetResult == DbInitResult.corrupted) {
                // Still broken — show dialog again
                _showCorruptionDialog();
              } else {
                final container =
                    ProviderScope.containerOf(context, listen: false);
                await _goHome();
                if (!mounted) return;
                unawaited(_afterHomeReady(container));
              }
            },
            child: const Text('Reset Database'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SisuColors.proOnline,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.directions_boat,
              size: 80,
              color: Colors.white,
            ),
            const SizedBox(height: 24),
            Text(
              'Sisu Mate',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Nunito',
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Offshore-Ready Boating Suite',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.white70,
                    fontFamily: 'Nunito',
                  ),
            ),
            const SizedBox(height: 48),
            const CircularProgressIndicator(
              color: Colors.white,
              strokeWidth: 2,
            ),
          ],
        ),
      ),
    );
  }
}
