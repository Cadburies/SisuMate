import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../components/title_tile.dart';
import '../../core/di.dart';
import '../../models/models.dart';
import '../../services/predictwind_datahub_service.dart';

/// #263 — Anchor Alarm's gateway setup/onboarding screen: username/password,
/// "Discover" (tries [PredictWindDatahubService.knownLocalAddresses]) or a
/// manual IP:port fallback, "Test" to confirm a login actually works, then
/// "Save" persists the choice to [UserSettings] so the Anchor Alarm screen
/// uses it on every future connection instead of the dart-defines default.
///
/// YDWG-02-style raw-NMEA gateways are out of scope here — that class of
/// device isn't behind a LuCI login at all, so "discover" for it will need
/// a different probe once one is available to test against (see #263).
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
    setState(() {
      _status = _Status.discovering;
      _discoveryRan = false;
      _discovered = [];
      _message = null;
    });
    final found = await widget.hubService.discoverLocalGateways(
      username: username,
      password: password,
      client: widget.httpClient,
    );
    if (!mounted) return;
    setState(() {
      _status = _Status.idle;
      _discovered = found;
      _discoveryRan = true;
      if (found.isNotEmpty) {
        _selectedAddress = found.first;
        _manualCtrl.text = found.first;
      } else {
        _message = "No gateway found among this app's known local "
            "addresses — enter the IP:port shown on the Hub / router "
            'directly below and tap Test.';
        _messageIsError = false;
      }
    });
  }

  Future<void> _testManual() async {
    final address = _normalizedManualAddress();
    if (address == null) {
      setState(() {
        _message = 'Enter an address first, e.g. 10.10.10.1 or '
            '10.10.10.1:80.';
        _messageIsError = true;
      });
      return;
    }
    setState(() {
      _status = _Status.testing;
      _message = null;
    });
    final ok = await widget.hubService.testConnection(
      baseUrl: address,
      username: _usernameCtrl.text.trim(),
      password: _passwordCtrl.text,
      client: widget.httpClient,
    );
    if (!mounted) return;
    setState(() {
      _status = _Status.idle;
      if (ok) {
        _selectedAddress = address;
        _message = 'Connected — sign-in succeeded at $address.';
        _messageIsError = false;
      } else {
        _selectedAddress = null;
        _message = "Couldn't sign in at $address — check the address, "
            'username, and password.';
        _messageIsError = true;
      }
    });
  }

  /// Accepts a bare host/`host:port` and normalizes it to a full
  /// `http://…` base URL (matching what [PredictWindDatahubService]
  /// expects); passes a URL that already has a scheme through unchanged.
  String? _normalizedManualAddress() {
    final raw = _manualCtrl.text.trim();
    if (raw.isEmpty) return null;
    if (raw.startsWith('http://') || raw.startsWith('https://')) return raw;
    return 'http://$raw';
  }

  Future<void> _save() async {
    final repo = ref.read(userSettingsRepositoryProvider);
    final current = await ref.read(userSettingsProvider.future);
    final settings = current ?? UserSettings();
    settings
      ..predictwindHubUsername = _usernameCtrl.text.trim()
      ..predictwindHubPassword = _passwordCtrl.text
      ..predictwindHubLocalUrl = _selectedAddress ?? '';
    setState(() => _status = _Status.saving);
    await repo.updateSettings(settings);
    if (!mounted) return;
    setState(() {
      _status = _Status.idle;
      _message = 'Saved — the Anchor Alarm will use this gateway from now on.';
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
                            'app — needed for both the local-WiFi and '
                            'internet connection.',
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _usernameCtrl,
                            decoration:
                                const InputDecoration(labelText: 'Username'),
                            enabled: !busy,
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
                            'Find the gateway on the boat’s WiFi',
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            "Connect your phone to the boat's own WiFi "
                            'first, then tap Discover.',
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
                                        _manualCtrl.text = v ?? '';
                                      }),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  for (final address in _discovered)
                                    RadioListTile<String>(
                                      contentPadding: EdgeInsets.zero,
                                      dense: true,
                                      title: Text(address),
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
                            "Didn't find it? Enter it manually",
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'The IP address (and port, if shown) printed on '
                            "the Hub or your router's device list, e.g. "
                            '10.10.10.1.',
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _manualCtrl,
                                  decoration: const InputDecoration(
                                    labelText: 'IP : Port',
                                    hintText: '10.10.10.1',
                                  ),
                                  enabled: !busy,
                                  onChanged: (_) =>
                                      setState(() => _selectedAddress = null),
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
