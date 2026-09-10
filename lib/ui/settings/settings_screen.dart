import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../components/title_tile.dart';
import 'boat_polar_dialog.dart';
import 'llm_api_key_dialog.dart';
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
  /// When true (e.g. `/settings?openAiKeys=1`), open **AI API Keys** once
  /// after the first frame so a no-key AI action can drop the user on the
  /// exact paste-your-token dialog.
  final bool openAiKeys;

  const SettingsScreen({super.key, this.openAiKeys = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(authStateProvider);

    return _OpenAiKeysOnLaunch(
      enabled: openAiKeys,
      child: Scaffold(
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
                  if (!user.isAnonymous)
                    ListTile(
                      leading: const Icon(Icons.delete_forever, color: Colors.red),
                      title: const Text('Delete My Account',
                          style: TextStyle(color: Colors.red)),
                      subtitle: const Text(
                          'Permanently deletes your account and owned boat data'),
                      onTap: () => _handleDeleteAccount(context, ref),
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
          ListTile(
            leading: const Icon(Icons.cloud_upload_outlined),
            title: const Text('Upload crash log'),
            subtitle: const Text(
                'Send stored errors from this device so we can fix them'),
            onTap: () => _handleUploadCrashLog(context),
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

                        // #215: bring-your-own-key AI API key — local-only by
                        // default; everyone (owner or crew) can set their own.
                        activeBoatAsync.maybeWhen(
                          data: (activeBoat) {
                            if (activeBoat == null) return const SizedBox.shrink();
                            final keyCount = activeBoat.llmApiKeys
                                .where((e) => e.apiKey.isNotEmpty)
                                .length;
                            final activeShared = activeBoat
                                .activeLlmApiKeyEntry?.shared ??
                                false;
                            return ListTile(
                              leading: const Icon(Icons.smart_toy_outlined),
                              title: const Text('AI API Keys'),
                              subtitle: Text(keyCount == 0
                                  ? 'None set — bring your own to use AI features'
                                  : '$keyCount provider${keyCount == 1 ? '' : 's'} '
                                      'configured'
                                      '${activeShared ? ' — active key shared with crew' : ''}'),
                              trailing: const Icon(Icons.edit),
                              onTap: () => showLlmApiKeyDialog(context, ref),
                            );
                          },
                          orElse: () => const SizedBox.shrink(),
                        ),

                        // #236/#276: boat polar table + diagram.
                        activeBoatAsync.maybeWhen(
                          data: (activeBoat) {
                            if (activeBoat == null) return const SizedBox.shrink();
                            final pointCount = activeBoat.polar.length;
                            return Column(
                              children: [
                                ListTile(
                                  leading: const Icon(Icons.speed_outlined),
                                  title: const Text('Boat Polar Data'),
                                  subtitle: Text(pointCount == 0
                                      ? 'Not set — used for more realistic ETAs'
                                      : '$pointCount point${pointCount == 1 ? '' : 's'} set'),
                                  trailing: const Icon(Icons.edit),
                                  onTap: () => showDialog(
                                    context: context,
                                    builder: (_) =>
                                        BoatPolarDialog(boat: activeBoat),
                                  ),
                                ),
                                ListTile(
                                  leading: const Icon(Icons.radar_outlined),
                                  title: const Text('Polar diagram'),
                                  subtitle: const Text(
                                    'See curves fill in by sea state (smooth / rough)',
                                  ),
                                  trailing: const Icon(Icons.chevron_right),
                                  onTap: () =>
                                      context.push(AppRoutes.polarChart),
                                ),
                              ],
                            );
                          },
                          orElse: () => const SizedBox.shrink(),
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
          _buildSectionHeader(context, 'Boat instruments / GPS'),
          ListTile(
            leading: const Icon(Icons.sensors),
            title: const Text('DataHub, YDWG & Home Assistant'),
            subtitle: const Text(
              'Configure boat instrument gateways used by Anchor, '
              'Weather position, and polar sampling',
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push(AppRoutes.boatInstruments),
          ),
          const Divider(),
          _buildSectionHeader(context, 'Anchor Alarm'),
          Consumer(
            builder: (context, ref, child) {
              final settingsAsync = ref.watch(userSettingsProvider);
              return settingsAsync.when(
                data: (settings) =>
                    _AnchorAlarmSettingsSection(settings: settings),
                loading: () => const ListTile(title: Text('Loading...')),
                error: (e, _) => ListTile(title: Text('Error: $e')),
              );
            },
          ),
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

  Future<void> _handleUploadCrashLog(BuildContext context) async {
    final n = await ErrorLogService().uploadUnsent();
    if (!context.mounted) return;
    final msg = n == 0
        ? 'Nothing to upload (sign in if you have logs, or none are pending)'
        : 'Uploaded $n error${n == 1 ? '' : 's'}';
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  /// Irreversible + affects other crew on any boat this user owns, so this
  /// gates behind typing DELETE rather than a single tap (Factory Reset's
  /// pattern is local-only, so one confirm is enough there).
  void _handleDeleteAccount(BuildContext context, WidgetRef ref) {
    final confirmController = TextEditingController();
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            final canConfirm =
                confirmController.text.trim().toUpperCase() == 'DELETE';
            return AlertDialog(
              title: const Text('Delete My Account'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'This permanently deletes your account and any boats you '
                    'own, including their checklists, logs, inventory, and '
                    'crew data — for every crew member on that boat. This '
                    'cannot be undone.',
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: confirmController,
                    autofocus: true,
                    onChanged: (_) => setState(() {}),
                    decoration: const InputDecoration(
                      labelText: 'Type DELETE to confirm',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: !canConfirm
                      ? null
                      : () async {
                          Navigator.of(dialogContext).pop();
                          try {
                            await ref
                                .read(authServiceProvider)
                                .deleteAccount();
                            final dbService =
                                ref.read(databaseServiceProvider);
                            await dbService.factoryReset();
                            invalidateAfterFactoryReset(ref);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Account deleted'),
                                ),
                              );
                            }
                          } catch (e, st) {
                            unawaited(ErrorLogService().logException(e, st,
                                context:
                                    'settings_screen: deleteAccount'));
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                    content:
                                        Text('Could not delete account: $e')),
                              );
                            }
                          }
                        },
                  child: const Text('Delete Account',
                      style: TextStyle(color: Colors.red)),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

/// Runs [showLlmApiKeyDialog] once after the first frame when [enabled].
class _OpenAiKeysOnLaunch extends ConsumerStatefulWidget {
  final bool enabled;
  final Widget child;

  const _OpenAiKeysOnLaunch({required this.enabled, required this.child});

  @override
  ConsumerState<_OpenAiKeysOnLaunch> createState() =>
      _OpenAiKeysOnLaunchState();
}

class _OpenAiKeysOnLaunchState extends ConsumerState<_OpenAiKeysOnLaunch> {
  var _didOpen = false;

  @override
  void initState() {
    super.initState();
    if (!widget.enabled) return;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (_didOpen || !mounted) return;
      _didOpen = true;
      await showLlmApiKeyDialog(context, ref);
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
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

/// #256 — default chain-scope ratio new anchor drops are pre-filled with.
class _AnchorAlarmSettingsSection extends ConsumerStatefulWidget {
  final UserSettings? settings;
  const _AnchorAlarmSettingsSection({required this.settings});

  @override
  ConsumerState<_AnchorAlarmSettingsSection> createState() =>
      _AnchorAlarmSettingsSectionState();
}

class _AnchorAlarmSettingsSectionState
    extends ConsumerState<_AnchorAlarmSettingsSection> {
  late final TextEditingController _scopeRatioController;
  late final TextEditingController _rollerController;
  late final TextEditingController _minDepthController;
  late final TextEditingController _maxWindController;
  late bool _aisEnabled;

  @override
  void initState() {
    super.initState();
    final s = widget.settings;
    _scopeRatioController = TextEditingController(
      text: (s?.defaultAnchorScopeRatio ?? 5.0).toStringAsFixed(1),
    );
    _rollerController = TextEditingController(
      text: (s?.anchorRollerHeightMeters ?? 0).toStringAsFixed(1),
    );
    _minDepthController = TextEditingController(
      text: (s?.anchorMinDepthMeters ?? 0).toStringAsFixed(1),
    );
    _maxWindController = TextEditingController(
      text: (s?.anchorMaxWindKt ?? 0).toStringAsFixed(0),
    );
    _aisEnabled = s?.anchorAisAlarmEnabled ?? false;
  }

  @override
  void dispose() {
    _scopeRatioController.dispose();
    _rollerController.dispose();
    _minDepthController.dispose();
    _maxWindController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final ratio = double.tryParse(_scopeRatioController.text.trim());
    if (ratio == null || ratio <= 0) return;
    final roller = double.tryParse(_rollerController.text.trim()) ?? 0;
    final minDepth = double.tryParse(_minDepthController.text.trim()) ?? 0;
    final maxWind = double.tryParse(_maxWindController.text.trim()) ?? 0;
    final updated = (widget.settings ?? UserSettings())
      ..defaultAnchorScopeRatio = ratio
      ..anchorRollerHeightMeters = roller < 0 ? 0 : roller
      ..anchorMinDepthMeters = minDepth < 0 ? 0 : minDepth
      ..anchorMaxWindKt = maxWind < 0 ? 0 : maxWind
      ..anchorAisAlarmEnabled = _aisEnabled;
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
            controller: _scopeRatioController,
            decoration: const InputDecoration(
              labelText: 'Default chain scope ratio',
              helperText: 'e.g. 5.0 for 5:1 — chain paid out vs. depth + roller. '
                  'Suggests the alarm circle; editable per drop.',
              helperMaxLines: 2,
            ),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            onEditingComplete: _save,
            onTapOutside: (_) => _save(),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _rollerController,
            decoration: const InputDecoration(
              labelText: 'Anchor roller height above water (m)',
              helperText:
                  'Bow roller / freeboard to rode lead. Added to depth for '
                  'scope: radius ≈ (depth + roller) × ratio. Tide offsets '
                  'are not auto-applied yet.',
              helperMaxLines: 3,
            ),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            onEditingComplete: _save,
            onTapOutside: (_) => _save(),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _minDepthController,
            decoration: const InputDecoration(
              labelText: 'Min depth alarm (m)',
              helperText: 'Alarm when live depth falls below this. 0 = off.',
              helperMaxLines: 2,
            ),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            onEditingComplete: _save,
            onTapOutside: (_) => _save(),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _maxWindController,
            decoration: const InputDecoration(
              labelText: 'Strong wind alarm (kn)',
              helperText:
                  'Alarm when apparent wind (or true if AWS missing) exceeds '
                  'this. 0 = off. Uses system alert + haptic.',
              helperMaxLines: 3,
            ),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            onEditingComplete: _save,
            onTapOutside: (_) => _save(),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('AIS collision alarm'),
            subtitle: const Text(
              'Armed for when an AIS feed is available. No ship targets '
              'in-app yet — this will not fire until a feed is wired.',
            ),
            value: _aisEnabled,
            onChanged: (v) {
              setState(() => _aisEnabled = v);
              _save();
            },
          ),
        ],
      ),
    );
  }
}
