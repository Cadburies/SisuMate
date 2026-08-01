import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../components/title_tile.dart';
import '../../core/app_router.dart';
import '../../core/colors.dart';
import '../../core/di.dart';
import '../../core/factory_reset.dart';
import '../../core/units.dart';
import '../../models/models.dart';
import '../../providers/shopping_provider.dart';
import '../../services/error_log_service.dart';
import '../../core/theme.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(authStateProvider);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const TitleTile(title: 'Settings'),
            Expanded(
              child: ListView(
        children: [
          _buildSectionHeader(context, 'Account'),
          userAsync.when(
            data: (user) {
              if (user == null) {
                return ListTile(
                  leading: const Icon(Icons.login),
                  title: const Text('Sign In'),
                  subtitle: const Text('Sign in to sync data (Pro only)'),
                  onTap: () => _showSignInDialog(context, ref),
                );
              }
              return Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.person),
                    title: Text(user.email ?? 'Unknown Email'),
                    subtitle: const Text('Signed In'),
                  ),
                  ListTile(
                    leading: const Icon(Icons.logout),
                    title: const Text('Sign Out'),
                    onTap: () => ref.read(authServiceProvider).signOut(),
                  ),
                ],
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, s) => ListTile(
              title: const Text('Auth Error'),
              subtitle: Text(e.toString()),
            ),
          ),
          const Divider(),
          _buildSectionHeader(context, 'Boats'),
          Consumer(
            builder: (context, ref, child) {
              final boatsAsync = ref.watch(boatsProvider);
              final activeBoatAsync = ref.watch(activeBoatProvider);
              final isProAsync = ref.watch(isProProvider);

              return isProAsync.when(
                data: (isPro) => boatsAsync.when(
                  data: (boats) {
                    return Column(
                      children: [
                        // Active Boat Selector
                        activeBoatAsync.when(
                          data: (activeBoat) => ListTile(
                            title: const Text('Active Boat'),
                            subtitle: Text(activeBoat?.name ?? 'No boat selected'),
                            trailing: PopupMenuButton<Boat>(
                              onSelected: (boat) async {
                                final userSettings = await ref.read(userSettingsProvider.future);
                                if (userSettings != null) {
                                  userSettings.activeBoatSupabaseId = boat.supabaseId;
                                  await ref.read(userSettingsRepositoryProvider).updateSettings(userSettings);
                                  ref.invalidate(userSettingsProvider);
                                  ref.invalidate(activeBoatProvider);
                                }
                              },
                              itemBuilder: (context) => boats.map((boat) => PopupMenuItem(
                                value: boat,
                                child: Text(boat.name),
                              )).toList(),
                              child: const Icon(Icons.arrow_drop_down),
                            ),
                          ),
                          loading: () => const ListTile(
                            title: Text('Active Boat'),
                            subtitle: Text('Loading...'),
                          ),
                          error: (e, _) => ListTile(
                            title: const Text('Active Boat'),
                            subtitle: Text('Error: $e'),
                          ),
                        ),

                        // Boat Management (Pro only)
                        if (isPro) ...[
                          const Divider(),
                          ListTile(
                            title: const Text('Manage Boats'),
                            subtitle: const Text('Add, edit, or delete boats'),
                            trailing: const Icon(Icons.directions_boat),
                            onTap: () => context.push(AppRoutes.boats),
                          ),
                        ] else if (boats.length <= 1) ...[
                          const ListTile(
                            title: Text('Boat Management'),
                            subtitle: Text('Upgrade to Pro for multiple boats'),
                            trailing: Icon(Icons.lock),
                          ),
                        ],
                      ],
                    );
                  },
                  loading: () => const ListTile(
                    title: Text('Active Boat'),
                    subtitle: Text('Loading boats...'),
                  ),
                  error: (e, _) => ListTile(
                    title: const Text('Active Boat'),
                    subtitle: Text('Error loading boats: $e'),
                  ),
                ),
                loading: () => const ListTile(
                  title: Text('Active Boat'),
                  subtitle: Text('Loading subscription...'),
                ),
                error: (e, _) => ListTile(
                  title: const Text('Active Boat'),
                  subtitle: Text('Error: $e'),
                ),
              );
            },
          ),
          const Divider(),
          _buildSectionHeader(context, 'Appearance'),
          Consumer(
            builder: (context, ref, child) {
              final themeMode = ref.watch(themeModeProvider);
              return ListTile(
                leading: Icon(
                  themeMode == ThemeMode.dark ? Icons.dark_mode : Icons.light_mode,
                ),
                title: const Text('Theme'),
                subtitle: Text(
                  themeMode == ThemeMode.dark ? 'Dark Theme' : 'Light Theme'
                ),
                trailing: PopupMenuButton<ThemeMode>(
                  onSelected: (ThemeMode mode) {
                    final themeNotifier = ref.read(themeModeProvider.notifier);
                    switch (mode) {
                      case ThemeMode.light:
                        themeNotifier.setLightTheme();
                        break;
                      case ThemeMode.dark:
                        themeNotifier.setDarkTheme();
                        break;
                      case ThemeMode.system:
                        // For now, default to light if system is selected
                        themeNotifier.setLightTheme();
                        break;
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: ThemeMode.light,
                      child: Text('Light Theme'),
                    ),
                    const PopupMenuItem(
                      value: ThemeMode.dark,
                      child: Text('Dark Theme'),
                    ),
                  ],
                  child: const Icon(Icons.arrow_drop_down),
                ),
              );
            },
          ),
          const Divider(),
          _buildSectionHeader(context, 'Units'),
          const _UnitsSettingsSection(),
          const Divider(),
          _buildSectionHeader(context, 'Email & Sharing'),
          Consumer(
            builder: (context, ref, child) {
              final settingsAsync = ref.watch(userSettingsProvider);
              return settingsAsync.when(
                data: (settings) => _EmailSettingsFields(settings: settings),
                loading: () => const ListTile(title: Text('Loading...')),
                error: (e, _) => ListTile(title: Text('Error: $e')),
              );
            },
          ),
          const Divider(),
          _buildSectionHeader(context, 'Data Management'),
          ListTile(
            leading: const Icon(Icons.monitor_heart_outlined),
            title: const Text('Sync Status'),
            subtitle: const Text('Outbox depth, conflicts, last sync'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push(AppRoutes.syncStatus),
          ),
          ListTile(
            title: const Text('Factory Reset'),
            subtitle: const Text('Reset database to factory state'),
            trailing: const Icon(Icons.warning, color: Colors.red),
            onTap: () => _handleFactoryReset(context, ref),
          ),
          const SizedBox(height: 24),
        ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
          color: SisuColors.getTextSecondaryColor(isDark),
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  void _showSignInDialog(BuildContext context, WidgetRef ref) {
    final emailController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign In'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Enter your email to receive a magic link to sign in.'),
            const SizedBox(height: 16),
            TextField(
              controller: emailController,
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final email = emailController.text.trim();
              if (email.isNotEmpty) {
                Navigator.pop(context);
                try {
                  await ref
                      .read(authServiceProvider)
                      .signInWithMagicLink(email);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Magic link sent! Check your email.'),
                      ),
                    );
                  }
                } catch (e, st) {
                  unawaited(ErrorLogService().logException(e, st,
                      context: 'settings_screen: signInWithMagicLink'));
                  if (context.mounted) {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text('Error: $e')));
                  }
                }
              }
            },
            child: const Text('Send Magic Link'),
          ),
        ],
      ),
    );
  }

  void _handleFactoryReset(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Factory Reset'),
          content: const Text(
            'This will reset the database to its initial factory state, deleting all user data. This action cannot be undone. Are you sure?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                final dbService = ref.read(databaseServiceProvider);
                await dbService.factoryReset();
                invalidateAfterFactoryReset(ref);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Database reset to factory state'),
                    ),
                  );
                }
              },
              child: const Text('Reset', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }
}

/// Marine-style unit profile: presets (like Garmin) + per-category overrides.
/// Storage remains metric; these only affect display/input conversion.
class _UnitsSettingsSection extends ConsumerWidget {
  const _UnitsSettingsSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefs = ref.watch(unitPrefsProvider);
    final notifier = ref.read(unitPrefsProvider.notifier);
    final preset = prefs.matchingPreset;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: Text(
            'Database stays metric. Choose how values appear in the app.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              ChoiceChip(
                label: const Text('Marine'),
                selected: preset == UnitPreset.marine,
                onSelected: (_) => notifier.applyPreset(UnitPreset.marine),
              ),
              ChoiceChip(
                label: const Text('US'),
                selected: preset == UnitPreset.us,
                onSelected: (_) => notifier.applyPreset(UnitPreset.us),
              ),
              ChoiceChip(
                label: const Text('Metric'),
                selected: preset == UnitPreset.metric,
                onSelected: (_) => notifier.applyPreset(UnitPreset.metric),
              ),
              if (preset == null)
                const Chip(
                  label: Text('Custom'),
                  avatar: Icon(Icons.tune, size: 16),
                ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
          child: Text(
            preset == UnitPreset.marine
                ? 'L, C, kn, m, NM - common for metric sailors'
                : preset == UnitPreset.us
                    ? 'gal, F, kn, ft, NM'
                    : preset == UnitPreset.metric
                        ? 'L, C, km/h, m, km'
                        : 'Mixed units - adjust rows below',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
        const SizedBox(height: 8),
        _unitRow<VolumeUnitPref>(
          context,
          icon: Icons.local_gas_station_outlined,
          title: 'Volume & fuel',
          subtitle: 'Cooking, bar, fuel burn',
          value: prefs.volume,
          labels: const {
            VolumeUnitPref.liters: 'Liters',
            VolumeUnitPref.usGallons: 'US gal',
          },
          onChanged: notifier.setVolume,
        ),
        _unitRow<TempUnitPref>(
          context,
          icon: Icons.thermostat_outlined,
          title: 'Temperature',
          subtitle: 'Weather, recipes',
          value: prefs.temperature,
          labels: const {
            TempUnitPref.celsius: 'C',
            TempUnitPref.fahrenheit: 'F',
          },
          onChanged: notifier.setTemperature,
        ),
        _unitRow<SpeedUnitPref>(
          context,
          icon: Icons.air,
          title: 'Wind speed',
          subtitle: 'Current wind, gusts, forecast',
          value: prefs.windSpeed,
          labels: const {
            SpeedUnitPref.knots: 'kn',
            SpeedUnitPref.kmh: 'km/h',
            SpeedUnitPref.mph: 'mph',
            SpeedUnitPref.metersPerSecond: 'm/s',
          },
          onChanged: notifier.setWindSpeed,
        ),
        _unitRow<SpeedUnitPref>(
          context,
          icon: Icons.speed,
          title: 'Boat / SOG speed',
          subtitle: 'Passage planner, speed over ground',
          value: prefs.boatSpeed,
          labels: const {
            SpeedUnitPref.knots: 'kn',
            SpeedUnitPref.kmh: 'km/h',
            SpeedUnitPref.mph: 'mph',
            SpeedUnitPref.metersPerSecond: 'm/s',
          },
          onChanged: notifier.setBoatSpeed,
        ),
        _unitRow<DepthUnitPref>(
          context,
          icon: Icons.waves_outlined,
          title: 'Depth & waves',
          subtitle: 'Charted depth, wave height',
          value: prefs.depth,
          labels: const {
            DepthUnitPref.meters: 'm',
            DepthUnitPref.feet: 'ft',
            DepthUnitPref.fathoms: 'fm',
          },
          onChanged: notifier.setDepth,
        ),
        _unitRow<DistanceUnitPref>(
          context,
          icon: Icons.straighten,
          title: 'Distance',
          subtitle: 'Passage planning',
          value: prefs.distance,
          labels: const {
            DistanceUnitPref.nauticalMiles: 'NM',
            DistanceUnitPref.kilometers: 'km',
            DistanceUnitPref.statuteMiles: 'mi',
          },
          onChanged: notifier.setDistance,
        ),
      ],
    );
  }

  Widget _unitRow<T extends Enum>(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required T value,
    required Map<T, String> labels,
    required Future<void> Function(T) onChanged,
  }) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: DropdownButton<T>(
        value: value,
        underline: const SizedBox.shrink(),
        items: [
          for (final e in labels.entries)
            DropdownMenuItem(value: e.key, child: Text(e.value)),
        ],
        onChanged: (v) {
          if (v != null) onChanged(v);
        },
      ),
    );
  }
}

class _EmailSettingsFields extends ConsumerStatefulWidget {
  final UserSettings? settings;
  const _EmailSettingsFields({required this.settings});

  @override
  ConsumerState<_EmailSettingsFields> createState() => _EmailSettingsFieldsState();
}

class _EmailSettingsFieldsState extends ConsumerState<_EmailSettingsFields> {
  late final TextEditingController _fromNameController;
  late final TextEditingController _replyToController;
  late final TextEditingController _boatNameController;

  @override
  void initState() {
    super.initState();
    _fromNameController = TextEditingController(text: widget.settings?.fromName ?? '');
    _replyToController = TextEditingController(text: widget.settings?.replyToEmail ?? '');
    _boatNameController = TextEditingController(text: widget.settings?.boatName ?? '');
  }

  @override
  void dispose() {
    _fromNameController.dispose();
    _replyToController.dispose();
    _boatNameController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final updated = (widget.settings ?? UserSettings())
      ..fromName =
          _fromNameController.text.trim().isEmpty ? null : _fromNameController.text.trim()
      ..replyToEmail =
          _replyToController.text.trim().isEmpty ? null : _replyToController.text.trim()
      ..boatName =
          _boatNameController.text.trim().isEmpty ? null : _boatNameController.text.trim();
    await ref.read(userSettingsRepositoryProvider).updateSettings(updated);
    ref.invalidate(userSettingsProvider);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Column(
        children: [
          TextField(
            controller: _fromNameController,
            decoration: const InputDecoration(labelText: 'From name (email signature)'),
            onEditingComplete: _save,
            onTapOutside: (_) => _save(),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _replyToController,
            decoration: const InputDecoration(labelText: 'Reply-to email'),
            keyboardType: TextInputType.emailAddress,
            onEditingComplete: _save,
            onTapOutside: (_) => _save(),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _boatNameController,
            decoration: const InputDecoration(labelText: 'Boat name (used in email subjects)'),
            onEditingComplete: _save,
            onTapOutside: (_) => _save(),
          ),
          const SizedBox(height: 4),
        ],
      ),
    );
  }
}
