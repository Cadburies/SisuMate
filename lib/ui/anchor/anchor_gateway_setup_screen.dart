import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../components/title_tile.dart';
import '../../core/di.dart';
import '../../models/models.dart';
import '../../services/predictwind_datahub_service.dart';

/// #263 — Anchor Alarm's gateway setup/onboarding screen: username/password,
/// "Discover" (tries known **local** Hub IPs *and* PredictWind **remote**
/// tunnel URLs with the entered credentials), manual address + "Test", then
/// "Save" to [UserSettings].
///
/// YDWG-02-style raw-NMEA gateways are out of scope here — that class of
/// device isn't behind a LuCI login at all (see #263).
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

enum _Status { idle, discovering, testing, saving }

class _AnchorGatewaySetupScreenState
    extends ConsumerState<AnchorGatewaySetupScreen> {
  final _usernameCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _manualCtrl = TextEditingController();

  _Status _status = _Status.idle;
  List<String> _discovered = [];
  bool _discoveryRan = false;
  String? _selectedAddress;
  String? _message;
  bool _messageIsError = false;

  bool _loadedFromSettings = false;

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _passwordCtrl.dispose();
    _manualCtrl.dispose();
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
  }

  Future<void> _discover() async {
    final username = _usernameCtrl.text.trim();
    final password = _passwordCtrl.text;
    if (username.isEmpty || password.isEmpty) {
      setState(() {
        _message = 'Enter username and password before Discover.';
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
      _message = result.summary;
      _messageIsError = result.workingAddresses.isEmpty;
      if (result.workingAddresses.isNotEmpty) {
        // Prefer a remote hit when both exist? Prefer first (local first in
        // list order) — on boat that's better; off boat only remotes succeed.
        _selectedAddress = result.workingAddresses.first;
        _manualCtrl.text = result.workingAddresses.first;
      }
    });
  }

  Future<void> _testManual() async {
    final address = _normalizedManualAddress();
    if (address == null) {
      setState(() {
        _message =
            'Enter an address first, e.g. http://192.168.10.31 or '
            'http://remote.rdsensing.com:36121';
        _messageIsError = true;
      });
      return;
    }
    final username = _usernameCtrl.text.trim();
    final password = _passwordCtrl.text;
    if (username.isEmpty || password.isEmpty) {
      setState(() {
        _message = 'Enter username and password before Test.';
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
      if (result.ok) {
        _selectedAddress = address;
        _manualCtrl.text = address;
        _message = 'Connected at $address. ${result.detail ?? ''} '
            'Tap Save to use this gateway.';
        _messageIsError = false;
      } else {
        // Keep the typed address selected so Save still works if the user
        // wants to persist it for later (tunnel offline right now).
        _selectedAddress = address;
        _message = "Couldn't connect to $address. "
            '${result.detail ?? "Check address, username, and password."}';
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

  /// Address to persist: selected radio, else whatever is in the manual
  /// field (so typing a remote URL and tapping Save actually stores it —
  /// previously onChanged cleared selection and Save wrote '').
  String? _addressToSave() =>
      _selectedAddress?.trim().isNotEmpty == true
          ? _selectedAddress!.trim()
          : _normalizedManualAddress();

  Future<void> _save() async {
    final address = _addressToSave();
    final username = _usernameCtrl.text.trim();
    final password = _passwordCtrl.text;

    if (username.isEmpty || password.isEmpty) {
      setState(() {
        _message = 'Enter username and password before saving.';
        _messageIsError = true;
      });
      return;
    }
    if (address == null || address.isEmpty) {
      setState(() {
        _message =
            'Enter or Discover a gateway address before saving '
            '(e.g. http://remote.rdsensing.com:36121).';
        _messageIsError = true;
      });
      return;
    }

    final repo = ref.read(userSettingsRepositoryProvider);
    final current = await ref.read(userSettingsProvider.future);
    final settings = current ?? UserSettings();
    settings
      ..predictwindHubUsername = username
      ..predictwindHubPassword = password
      ..predictwindHubLocalUrl = address;
    setState(() => _status = _Status.saving);
    await repo.updateSettings(settings);
    if (!mounted) return;
    final kind = PredictWindDatahubService.isPrivateLanUrl(address)
        ? 'boat WiFi (local)'
        : 'internet remote access';
    setState(() {
      _status = _Status.idle;
      _selectedAddress = address;
      _manualCtrl.text = address;
      _message =
          'Saved $address as $kind. '
          'The Anchor Alarm will use this login from now on.';
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
                            'PredictWind Hub login',
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
                            decoration:
                                const InputDecoration(labelText: 'Username'),
                            enabled: !busy,
                            autocorrect: false,
                            enableSuggestions: false,
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _passwordCtrl,
                            decoration:
                                const InputDecoration(labelText: 'Password'),
                            obscureText: true,
                            enabled: !busy,
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
                            'Discover gateway',
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Probes known boat-WiFi addresses and PredictWind '
                            'internet tunnel URLs with the login above. '
                            'Works at the dock (local) and away from the boat '
                            '(remote) when the Hub tunnel is online.',
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
                              label: const Text('Discover'),
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
                            'Or enter an address manually',
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Local example: http://192.168.10.31\n'
                            'Remote example: http://remote.rdsensing.com:36121\n'
                            '(Prefer http for remote — https often uses a '
                            'self-signed certificate the phone rejects.)',
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _manualCtrl,
                                  decoration: const InputDecoration(
                                    labelText: 'Hub address',
                                    hintText:
                                        'http://remote.rdsensing.com:36121',
                                  ),
                                  enabled: !busy,
                                  autocorrect: false,
                                  enableSuggestions: false,
                                  onChanged: (raw) {
                                    final trimmed = raw.trim();
                                    setState(() {
                                      // Keep selection in sync with what the
                                      // user typed so Save persists it.
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
                                onPressed: busy ? null : _testManual,
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
