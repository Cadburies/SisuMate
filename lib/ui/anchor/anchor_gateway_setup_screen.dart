import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../components/title_tile.dart';
import '../../core/di.dart';
import '../../models/models.dart';
import '../../services/predictwind_datahub_service.dart';

/// #263 — Anchor Alarm's gateway setup/onboarding screen.
///
/// **PredictWind DataHub** (LuCI / nmead): username/password, Discover
/// (local + remote tunnel URLs), manual address + Test, Save.
///
/// **YDWG-02** (Yacht Devices web UI + NMEA): separate address +
/// username/password fields (defaults from dart-defines / factory admin),
/// Test (web login `POST /login`), Save. NMEA stream parse is still a
/// follow-up; this ships config + login verification.
class AnchorGatewaySetupScreen extends ConsumerStatefulWidget {
  const AnchorGatewaySetupScreen({
    super.key,
    this.hubService = const PredictWindDatahubService(),
    this.httpClient,
  });

  final PredictWindDatahubService hubService;

  /// Test-injection seam — mirrors `AnchorAlarmScreen.httpClient` so the
  /// widget test can fake network responses instead of hitting a real host.
  final http.Client? httpClient;

  @override
  ConsumerState<AnchorGatewaySetupScreen> createState() =>
      _AnchorGatewaySetupScreenState();
}

enum _Status { idle, discovering, testing, testingYdwg, saving }

class _AnchorGatewaySetupScreenState
    extends ConsumerState<AnchorGatewaySetupScreen> {
  late final TextEditingController _usernameCtrl;
  late final TextEditingController _passwordCtrl;
  late final TextEditingController _manualCtrl;

  late final TextEditingController _ydwgUrlCtrl;
  late final TextEditingController _ydwgUserCtrl;
  late final TextEditingController _ydwgPassCtrl;

  _Status _status = _Status.idle;
  List<String> _discovered = [];
  bool _discoveryRan = false;
  bool _ydwgReachable = false;
  String? _selectedAddress;
  String? _message;
  bool _messageIsError = false;

  bool _loadedFromSettings = false;

  @override
  void initState() {
    super.initState();
    final remote = PredictWindDatahubService.defaultDataHubRemoteUrlResolved;
    _usernameCtrl = TextEditingController();
    _passwordCtrl = TextEditingController();
    _manualCtrl = TextEditingController(text: remote);
    _selectedAddress = remote;

    // Example defaults — user can change; saved settings overwrite on load.
    _ydwgUrlCtrl = TextEditingController(
      text: PredictWindDatahubService.defaultYdwgUrl,
    );
    _ydwgUserCtrl = TextEditingController(
      text: PredictWindDatahubService.defaultYdwgUsernameResolved,
    );
    _ydwgPassCtrl = TextEditingController(
      text: PredictWindDatahubService.defaultYdwgPasswordResolved,
    );
  }

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _passwordCtrl.dispose();
    _manualCtrl.dispose();
    _ydwgUrlCtrl.dispose();
    _ydwgUserCtrl.dispose();
    _ydwgPassCtrl.dispose();
    super.dispose();
  }

  void _loadFromSettings(UserSettings? settings) {
    if (_loadedFromSettings || settings == null) return;
    _loadedFromSettings = true;
    _usernameCtrl.text = settings.predictwindHubUsername;
    _passwordCtrl.text = settings.predictwindHubPassword;
    if (settings.predictwindHubLocalUrl.isNotEmpty) {
      _manualCtrl.text = settings.predictwindHubLocalUrl;
      _selectedAddress = settings.predictwindHubLocalUrl;
    }
    if (settings.ydwgUrl.isNotEmpty) {
      _ydwgUrlCtrl.text = settings.ydwgUrl;
    }
    if (settings.ydwgUsername.isNotEmpty) {
      _ydwgUserCtrl.text = settings.ydwgUsername;
    }
    if (settings.ydwgPassword.isNotEmpty) {
      _ydwgPassCtrl.text = settings.ydwgPassword;
    }
  }

  Future<void> _discover() async {
    final username = _usernameCtrl.text.trim();
    final password = _passwordCtrl.text;
    if (username.isEmpty || password.isEmpty) {
      setState(() {
        _message = 'Enter DataHub username and password before Discover.';
        _messageIsError = true;
      });
      return;
    }
    setState(() {
      _status = _Status.discovering;
      _discoveryRan = false;
      _discovered = [];
      _message = null;
    });
    final result = await widget.hubService.discoverGateways(
      username: username,
      password: password,
      client: widget.httpClient,
    );
    if (!mounted) return;
    setState(() {
      _status = _Status.idle;
      _discovered = result.workingAddresses;
      _discoveryRan = true;
      _ydwgReachable = result.ydwgReachable;
      _message = result.summary;
      _messageIsError = result.workingAddresses.isEmpty && !result.ydwgReachable;
      if (result.workingAddresses.isNotEmpty) {
        _selectedAddress = result.workingAddresses.first;
        _manualCtrl.text = result.workingAddresses.first;
      }
      if (result.ydwgReachable) {
        // Pre-fill YDWG address when Discover sees the host.
        _ydwgUrlCtrl.text = PredictWindDatahubService.defaultYdwgUrl;
      }
    });
  }

  void _applyDataHubSuggestion(GatewayDefaultSuggestion s) {
    if (s.kind == GatewayDefaultKind.ydwg) {
      setState(() {
        _ydwgUrlCtrl.text = s.url;
        _message = s.tip;
        _messageIsError = false;
      });
      return;
    }
    setState(() {
      _selectedAddress = s.url;
      _manualCtrl.text = s.url;
      _message = s.tip;
      _messageIsError = false;
    });
  }

  String _helperForHubAddress() {
    final address = _selectedAddress ?? _normalizedManualAddress() ?? '';
    if (address == PredictWindDatahubService.defaultDataHubLocalUrl) {
      return 'Default for DataHub on boat WiFi / intranet';
    }
    if (address == PredictWindDatahubService.defaultDataHubRemoteUrlResolved ||
        address == PredictWindDatahubService.defaultDataHubRemoteUrl) {
      return 'Default for DataHub';
    }
    return 'DataHub Hub address (local or internet)';
  }

  Future<void> _testDataHub() async {
    final address = _normalizedManualAddress();
    if (address == null) {
      setState(() {
        _message =
            'Enter a DataHub address first, e.g. http://192.168.10.31 or '
            'http://remote.rdsensing.com:36121';
        _messageIsError = true;
      });
      return;
    }
    final username = _usernameCtrl.text.trim();
    final password = _passwordCtrl.text;
    if (username.isEmpty || password.isEmpty) {
      setState(() {
        _message = 'Enter DataHub username and password before Test.';
        _messageIsError = true;
      });
      return;
    }
    setState(() {
      _status = _Status.testing;
      _message = null;
    });
    final result = await widget.hubService.probeConnection(
      baseUrl: address,
      username: username,
      password: password,
      client: widget.httpClient,
    );
    if (!mounted) return;
    setState(() {
      _status = _Status.idle;
      _selectedAddress = address;
      _manualCtrl.text = address;
      if (result.ok) {
        _message = 'Connected to DataHub at $address. '
            '${result.detail ?? ''} Tap Save to keep this login.';
        _messageIsError = false;
      } else {
        _message = "Couldn't connect to DataHub at $address. "
            '${result.detail ?? "Check address, username, and password."}';
        _messageIsError = true;
      }
    });
  }

  Future<void> _testYdwg() async {
    final address = _normalizedYdwgAddress();
    if (address == null) {
      setState(() {
        _message =
            'Enter a YDWG address first, e.g. http://192.168.10.30';
        _messageIsError = true;
      });
      return;
    }
    final username = _ydwgUserCtrl.text.trim();
    final password = _ydwgPassCtrl.text;
    if (username.isEmpty || password.isEmpty) {
      setState(() {
        _message = 'Enter YDWG username and password before Test.';
        _messageIsError = true;
      });
      return;
    }
    setState(() {
      _status = _Status.testingYdwg;
      _message = null;
    });
    final result = await widget.hubService.probeYdwgLogin(
      baseUrl: address,
      username: username,
      password: password,
      client: widget.httpClient,
    );
    if (!mounted) return;
    setState(() {
      _status = _Status.idle;
      _ydwgUrlCtrl.text = address;
      _ydwgReachable = result.ok;
      if (result.ok) {
        _message =
            '${result.detail ?? "YDWG login OK at $address."} '
            'Web UI: $address/home.html — tap Save to keep these credentials.';
        _messageIsError = false;
      } else {
        _message = "Couldn't sign in to YDWG at $address. "
            '${result.detail ?? "Check address and credentials."}';
        _messageIsError = true;
      }
    });
  }

  /// Accepts a bare host/`host:port` and normalizes it to a full
  /// `http://…` base URL; passes a URL that already has a scheme through.
  String? _normalizedManualAddress() {
    final raw = _manualCtrl.text.trim();
    if (raw.isEmpty) return null;
    if (raw.startsWith('http://') || raw.startsWith('https://')) return raw;
    return 'http://$raw';
  }

  String? _normalizedYdwgAddress() {
    var raw = _ydwgUrlCtrl.text.trim();
    if (raw.isEmpty) return null;
    // Users may paste the home page path; strip it for the base URL.
    raw = raw.replaceFirst(RegExp(r'/home\.html/?$', caseSensitive: false), '');
    raw = raw.replaceFirst(RegExp(r'/login\.html.*$', caseSensitive: false), '');
    if (raw.endsWith('/')) raw = raw.substring(0, raw.length - 1);
    if (raw.startsWith('http://') || raw.startsWith('https://')) return raw;
    return 'http://$raw';
  }

  String? _addressToSave() =>
      _selectedAddress?.trim().isNotEmpty == true
          ? _selectedAddress!.trim()
          : _normalizedManualAddress();

  Future<void> _save() async {
    final address = _addressToSave();
    final username = _usernameCtrl.text.trim();
    final password = _passwordCtrl.text;
    final ydwgAddress = _normalizedYdwgAddress();
    final ydwgUser = _ydwgUserCtrl.text.trim();
    final ydwgPass = _ydwgPassCtrl.text;

    final hubUrl = (address != null && address.isNotEmpty) ? address : null;
    final yUrl =
        (ydwgAddress != null && ydwgAddress.isNotEmpty) ? ydwgAddress : null;
    final hasDataHub =
        username.isNotEmpty && password.isNotEmpty && hubUrl != null;
    final hasYdwg =
        ydwgUser.isNotEmpty && ydwgPass.isNotEmpty && yUrl != null;

    if (!hasDataHub && !hasYdwg) {
      setState(() {
        _message =
            'Fill in DataHub (address + login) and/or YDWG-02 '
            '(address + login) before saving.';
        _messageIsError = true;
      });
      return;
    }

    final repo = ref.read(userSettingsRepositoryProvider);
    final current = await ref.read(userSettingsProvider.future);
    final settings = current ?? UserSettings();

    final parts = <String>[];
    if (hasDataHub) {
      settings
        ..predictwindHubUsername = username
        ..predictwindHubPassword = password
        ..predictwindHubLocalUrl = hubUrl;
      final kind = PredictWindDatahubService.isPrivateLanUrl(hubUrl)
          ? 'boat WiFi (local)'
          : 'internet remote access';
      parts.add('DataHub $hubUrl ($kind)');
    }
    if (hasYdwg) {
      settings
        ..ydwgUrl = yUrl
        ..ydwgUsername = ydwgUser
        ..ydwgPassword = ydwgPass;
      parts.add('YDWG-02 $yUrl');
      _ydwgUrlCtrl.text = yUrl;
    }

    setState(() => _status = _Status.saving);
    await repo.updateSettings(settings);
    if (!mounted) return;
    setState(() {
      _status = _Status.idle;
      if (hasDataHub) {
        _selectedAddress = hubUrl;
        _manualCtrl.text = hubUrl;
      }
      _message =
          'Saved ${parts.join(' and ')}. '
          'The Anchor Alarm will use these settings from now on.';
      _messageIsError = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final settingsAsync = ref.watch(userSettingsProvider);
    settingsAsync.whenData(_loadFromSettings);
    final busy = _status != _Status.idle;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const TitleTile(title: 'Gateway Setup'),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(12),
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'PredictWind DataHub',
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'The same login you use on the Hub / PredictWind '
                            'app — needed for both the boat WiFi and the '
                            'internet (remote.rdsensing.com) path.',
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _usernameCtrl,
                            decoration: const InputDecoration(
                              labelText: 'DataHub username',
                            ),
                            enabled: !busy,
                            autocorrect: false,
                            enableSuggestions: false,
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _passwordCtrl,
                            decoration: const InputDecoration(
                              labelText: 'DataHub password',
                            ),
                            obscureText: true,
                            enabled: !busy,
                          ),
                          const SizedBox(height: 12),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: ElevatedButton.icon(
                              onPressed: busy ? null : _discover,
                              icon: _status == _Status.discovering
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2),
                                    )
                                  : const Icon(Icons.wifi_find),
                              label: const Text('Discover DataHub'),
                            ),
                          ),
                          if (_discoveryRan && _discovered.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            Text(
                              'Found:',
                              style: Theme.of(context).textTheme.labelLarge,
                            ),
                            RadioGroup<String>(
                              groupValue: _selectedAddress,
                              onChanged: busy
                                  ? (_) {}
                                  : (v) => setState(() {
                                        _selectedAddress = v;
                                        if (v != null) _manualCtrl.text = v;
                                      }),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  for (final address in _discovered)
                                    RadioListTile<String>(
                                      contentPadding: EdgeInsets.zero,
                                      dense: true,
                                      title: Text(address),
                                      subtitle: Text(
                                        PredictWindDatahubService
                                                .isPrivateLanUrl(address)
                                            ? 'Boat WiFi (local)'
                                            : 'Internet (remote access)',
                                      ),
                                      value: address,
                                    ),
                                ],
                              ),
                            ),
                          ],
                          if (_discoveryRan && _ydwgReachable) ...[
                            const SizedBox(height: 8),
                            Text(
                              'Also: YDWG-02 host reachable '
                              '(see YDWG section below).',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                          const SizedBox(height: 12),
                          Text(
                            'DataHub address',
                            style: Theme.of(context).textTheme.labelLarge,
                          ),
                          const SizedBox(height: 4),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              for (final s in [
                                ...PredictWindDatahubService.internetDefaults,
                                ...PredictWindDatahubService.boatLanDefaults
                                    .where((s) =>
                                        s.kind ==
                                        GatewayDefaultKind.dataHubLocal),
                              ])
                                ActionChip(
                                  label: Text(s.label),
                                  tooltip: s.tip,
                                  onPressed: busy
                                      ? null
                                      : () => _applyDataHubSuggestion(s),
                                ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _manualCtrl,
                                  decoration: InputDecoration(
                                    labelText: 'Hub address',
                                    hintText: PredictWindDatahubService
                                        .defaultDataHubRemoteUrlResolved,
                                    helperText: _helperForHubAddress(),
                                  ),
                                  enabled: !busy,
                                  autocorrect: false,
                                  enableSuggestions: false,
                                  onChanged: (raw) {
                                    final trimmed = raw.trim();
                                    setState(() {
                                      if (trimmed.isEmpty) {
                                        _selectedAddress = null;
                                      } else if (trimmed.startsWith('http://') ||
                                          trimmed.startsWith('https://')) {
                                        _selectedAddress = trimmed;
                                      } else {
                                        _selectedAddress = 'http://$trimmed';
                                      }
                                    });
                                  },
                                ),
                              ),
                              const SizedBox(width: 8),
                              OutlinedButton(
                                onPressed: busy ? null : _testDataHub,
                                child: _status == _Status.testing
                                    ? const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                            strokeWidth: 2),
                                      )
                                    : const Text('Test'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'YDWG-02 (NMEA gateway)',
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Yacht Devices YDWG-02 on the boat network. '
                            'Web UI at …/home.html (factory login admin / admin). '
                            'Defaults below are examples for this boat — change '
                            'if your device uses another IP or password.\n'
                            'Default: ${PredictWindDatahubService.defaultYdwgUrl}',
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _ydwgUrlCtrl,
                            decoration: InputDecoration(
                              labelText: 'YDWG address',
                              hintText:
                                  PredictWindDatahubService.defaultYdwgUrl,
                              helperText:
                                  'Default for YDWG-02 (e.g. http://192.168.10.30)',
                            ),
                            enabled: !busy,
                            autocorrect: false,
                            enableSuggestions: false,
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _ydwgUserCtrl,
                            decoration: const InputDecoration(
                              labelText: 'YDWG username',
                              hintText: 'admin',
                            ),
                            enabled: !busy,
                            autocorrect: false,
                            enableSuggestions: false,
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _ydwgPassCtrl,
                            decoration: const InputDecoration(
                              labelText: 'YDWG password',
                              hintText: 'admin',
                            ),
                            obscureText: true,
                            enabled: !busy,
                          ),
                          const SizedBox(height: 12),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: OutlinedButton.icon(
                              onPressed: busy ? null : _testYdwg,
                              icon: _status == _Status.testingYdwg
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2),
                                    )
                                  : const Icon(Icons.login),
                              label: const Text('Test YDWG login'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (_message != null) ...[
                    const SizedBox(height: 12),
                    Card(
                      color: _messageIsError
                          ? Theme.of(context).colorScheme.errorContainer
                          : Theme.of(context).colorScheme.primaryContainer,
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Text(_message!),
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: busy ? null : _save,
                    icon: _status == _Status.saving
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.save),
                    label: const Text('Save'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
