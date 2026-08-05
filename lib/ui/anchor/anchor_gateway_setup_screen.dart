import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../components/title_tile.dart';
import '../../core/di.dart';
import '../../models/models.dart';
import '../../services/home_assistant_service.dart';
import '../../services/predictwind_datahub_service.dart';

/// #263 — Anchor Alarm's gateway setup/onboarding screen.
///
/// **PredictWind DataHub** (LuCI / nmead): username/password, Discover
/// (local + remote tunnel URLs), manual address + Test, Save.
///
/// **YDWG-02** (Yacht Devices web UI + NMEA): address + username/password,
/// Test web login. NMEA stream still deferred.
///
/// **Home Assistant**: same dual-path model as DataHub — local (boat LAN)
/// and internet (Nabu Casa / reverse proxy), shared long-lived token +
/// entity IDs. Failover tries HA local with other local sources, then HA
/// internet with other remote sources.
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

enum _Status {
  idle,
  discovering,
  testing,
  testingYdwg,
  testingHa,
  saving,
}

class _AnchorGatewaySetupScreenState
    extends ConsumerState<AnchorGatewaySetupScreen> {
  late final TextEditingController _usernameCtrl;
  late final TextEditingController _passwordCtrl;
  late final TextEditingController _manualCtrl;

  late final TextEditingController _ydwgUrlCtrl;
  late final TextEditingController _ydwgUserCtrl;
  late final TextEditingController _ydwgPassCtrl;

  late final TextEditingController _haUrlCtrl;
  late final TextEditingController _haRemoteUrlCtrl;
  late final TextEditingController _haTokenCtrl;
  late final TextEditingController _haGpsEntityCtrl;
  late final TextEditingController _haLatEntityCtrl;
  late final TextEditingController _haLonEntityCtrl;
  late final TextEditingController _haWindSpeedCtrl;
  late final TextEditingController _haWindDirCtrl;
  late final TextEditingController _haDepthCtrl;

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

    _haUrlCtrl = TextEditingController(
      text: HomeAssistantService.defaultUrl.isNotEmpty
          ? HomeAssistantService.defaultUrl
          : 'http://homeassistant.local:8123',
    );
    _haRemoteUrlCtrl = TextEditingController(
      text: HomeAssistantService.defaultRemoteUrl,
    );
    _haTokenCtrl = TextEditingController(
      text: HomeAssistantService.defaultToken,
    );
    _haGpsEntityCtrl = TextEditingController(
      text: HomeAssistantService.defaultGpsEntity.isNotEmpty
          ? HomeAssistantService.defaultGpsEntity
          : 'device_tracker.boat',
    );
    _haLatEntityCtrl = TextEditingController(
      text: HomeAssistantService.defaultLatEntity,
    );
    _haLonEntityCtrl = TextEditingController(
      text: HomeAssistantService.defaultLonEntity,
    );
    _haWindSpeedCtrl = TextEditingController(
      text: HomeAssistantService.defaultWindSpeedEntity,
    );
    _haWindDirCtrl = TextEditingController(
      text: HomeAssistantService.defaultWindDirEntity,
    );
    _haDepthCtrl = TextEditingController(
      text: HomeAssistantService.defaultDepthEntity,
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
    _haUrlCtrl.dispose();
    _haRemoteUrlCtrl.dispose();
    _haTokenCtrl.dispose();
    _haGpsEntityCtrl.dispose();
    _haLatEntityCtrl.dispose();
    _haLonEntityCtrl.dispose();
    _haWindSpeedCtrl.dispose();
    _haWindDirCtrl.dispose();
    _haDepthCtrl.dispose();
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
    if (settings.homeAssistantUrl.isNotEmpty) {
      _haUrlCtrl.text = settings.homeAssistantUrl;
    }
    if (settings.homeAssistantRemoteUrl.isNotEmpty) {
      _haRemoteUrlCtrl.text = settings.homeAssistantRemoteUrl;
    }
    if (settings.homeAssistantToken.isNotEmpty) {
      _haTokenCtrl.text = settings.homeAssistantToken;
    }
    if (settings.homeAssistantGpsEntity.isNotEmpty) {
      _haGpsEntityCtrl.text = settings.homeAssistantGpsEntity;
    }
    if (settings.homeAssistantLatEntity.isNotEmpty) {
      _haLatEntityCtrl.text = settings.homeAssistantLatEntity;
    }
    if (settings.homeAssistantLonEntity.isNotEmpty) {
      _haLonEntityCtrl.text = settings.homeAssistantLonEntity;
    }
    if (settings.homeAssistantWindSpeedEntity.isNotEmpty) {
      _haWindSpeedCtrl.text = settings.homeAssistantWindSpeedEntity;
    }
    if (settings.homeAssistantWindDirEntity.isNotEmpty) {
      _haWindDirCtrl.text = settings.homeAssistantWindDirEntity;
    }
    if (settings.homeAssistantDepthEntity.isNotEmpty) {
      _haDepthCtrl.text = settings.homeAssistantDepthEntity;
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

  String? _normalizedHaUrl(String raw) {
    final t = raw.trim();
    if (t.isEmpty) return null;
    if (t.startsWith('http://') || t.startsWith('https://')) {
      return t.endsWith('/') ? t.substring(0, t.length - 1) : t;
    }
    return 'http://$t';
  }

  Future<void> _testHa({required bool remote}) async {
    final url = _normalizedHaUrl(
      remote ? _haRemoteUrlCtrl.text : _haUrlCtrl.text,
    );
    final token = _haTokenCtrl.text.trim();
    if (url == null) {
      setState(() {
        _message = remote
            ? 'Enter a Home Assistant remote URL first '
                '(e.g. https://….ui.nabu.casa).'
            : 'Enter a Home Assistant local URL first '
                '(e.g. http://homeassistant.local:8123).';
        _messageIsError = true;
      });
      return;
    }
    if (token.isEmpty) {
      setState(() {
        _message =
            'Enter a Home Assistant long-lived access token before Test.';
        _messageIsError = true;
      });
      return;
    }
    setState(() {
      _status = _Status.testingHa;
      _message = null;
    });
    final svc = HomeAssistantService(baseUrl: url, token: token);
    final result = await svc.probeConnection(client: widget.httpClient);
    if (!mounted) return;
    setState(() {
      _status = _Status.idle;
      if (result.ok) {
        _message =
            '${result.detail ?? "Home Assistant OK."} '
            'Failover will try this ${remote ? "internet" : "local"} path. '
            'Tap Save to keep settings.';
        _messageIsError = false;
      } else {
        _message =
            "Couldn't reach Home Assistant at $url. "
            '${result.detail ?? "Check URL and token."}';
        _messageIsError = true;
      }
    });
  }

  Future<void> _save() async {
    final address = _addressToSave();
    final username = _usernameCtrl.text.trim();
    final password = _passwordCtrl.text;
    final ydwgAddress = _normalizedYdwgAddress();
    final ydwgUser = _ydwgUserCtrl.text.trim();
    final ydwgPass = _ydwgPassCtrl.text;
    // HA dual-path: local + internet (same idea as DataHub). If only one
    // URL is filled, classify by private-LAN vs public host.
    var haUrl = _normalizedHaUrl(_haUrlCtrl.text);
    var haRemote = _normalizedHaUrl(_haRemoteUrlCtrl.text);
    final haToken = _haTokenCtrl.text.trim();
    if (haUrl != null && haRemote == null) {
      if (!PredictWindDatahubService.isPrivateLanUrl(haUrl)) {
        haRemote = haUrl;
        haUrl = null;
      }
    } else if (haRemote != null && haUrl == null) {
      if (PredictWindDatahubService.isPrivateLanUrl(haRemote)) {
        haUrl = haRemote;
        haRemote = null;
      }
    }

    final hubUrl = (address != null && address.isNotEmpty) ? address : null;
    final yUrl =
        (ydwgAddress != null && ydwgAddress.isNotEmpty) ? ydwgAddress : null;
    final hasDataHub =
        username.isNotEmpty && password.isNotEmpty && hubUrl != null;
    final hasYdwg =
        ydwgUser.isNotEmpty && ydwgPass.isNotEmpty && yUrl != null;
    final hasHa = haToken.isNotEmpty && (haUrl != null || haRemote != null);

    if (!hasDataHub && !hasYdwg && !hasHa) {
      setState(() {
        _message =
            'Fill in at least one source: DataHub, YDWG-02, or Home Assistant '
            '(URL + token) before saving.';
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
    if (hasHa) {
      settings
        ..homeAssistantUrl = haUrl ?? ''
        ..homeAssistantRemoteUrl = haRemote ?? ''
        ..homeAssistantToken = haToken
        ..homeAssistantGpsEntity = _haGpsEntityCtrl.text.trim()
        ..homeAssistantLatEntity = _haLatEntityCtrl.text.trim()
        ..homeAssistantLonEntity = _haLonEntityCtrl.text.trim()
        ..homeAssistantWindSpeedEntity = _haWindSpeedCtrl.text.trim()
        ..homeAssistantWindDirEntity = _haWindDirCtrl.text.trim()
        ..homeAssistantDepthEntity = _haDepthCtrl.text.trim();
      parts.add(
        'Home Assistant'
        '${haUrl != null ? ' local $haUrl' : ''}'
        '${haRemote != null ? ' internet $haRemote' : ''}',
      );
      if (haUrl != null) _haUrlCtrl.text = haUrl;
      if (haRemote != null) _haRemoteUrlCtrl.text = haRemote;
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
          'Saved ${parts.join(' · ')}. '
          'Failover: DataHub local → YDWG NMEA → HA local → '
          'DataHub internet → HA internet.';
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
                                    : const Text('Test DataHub'),
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
                            'NMEA 0183 GPS/wind is read over TCP port 1456 '
                            '(YDWG factory default) on the same host — used in '
                            'local failover after DataHub.\n'
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
                  const SizedBox(height: 12),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Home Assistant',
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Same dual-path model as PredictWind DataHub: '
                            'local on boat WiFi/intranet, and internet '
                            '(Nabu Casa / reverse proxy) for beach-bar '
                            'failover when you are off the boat.\n'
                            'Shared long-lived access token (HA Profile → '
                            'Create Token). GPS entity should expose '
                            'latitude/longitude attributes '
                            '(e.g. device_tracker.boat), or use separate '
                            'lat/lon sensors.\n'
                            'Failover order: DataHub local → HA local → '
                            'DataHub internet → HA internet.',
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _haUrlCtrl,
                            decoration: const InputDecoration(
                              labelText: 'HA local URL (boat network)',
                              hintText: 'http://homeassistant.local:8123',
                              helperText:
                                  'Like DataHub local — used first on boat WiFi',
                            ),
                            enabled: !busy,
                            autocorrect: false,
                            enableSuggestions: false,
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _haRemoteUrlCtrl,
                            decoration: const InputDecoration(
                              labelText: 'HA internet URL',
                              hintText: 'https://….ui.nabu.casa',
                              helperText:
                                  'Like DataHub remote — beach-bar / cellular path',
                            ),
                            enabled: !busy,
                            autocorrect: false,
                            enableSuggestions: false,
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _haTokenCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Long-lived access token',
                              hintText: 'eyJ…',
                            ),
                            obscureText: true,
                            enabled: !busy,
                            autocorrect: false,
                            enableSuggestions: false,
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _haGpsEntityCtrl,
                            decoration: const InputDecoration(
                              labelText: 'GPS entity (preferred)',
                              hintText: 'device_tracker.boat',
                              helperText:
                                  'Entity with latitude/longitude attributes',
                            ),
                            enabled: !busy,
                            autocorrect: false,
                            enableSuggestions: false,
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _haLatEntityCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Lat sensor (optional)',
                              hintText: 'sensor.boat_latitude',
                            ),
                            enabled: !busy,
                            autocorrect: false,
                            enableSuggestions: false,
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _haLonEntityCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Lon sensor (optional)',
                              hintText: 'sensor.boat_longitude',
                            ),
                            enabled: !busy,
                            autocorrect: false,
                            enableSuggestions: false,
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _haWindSpeedCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Wind speed entity (optional)',
                              hintText: 'sensor.true_wind_speed',
                            ),
                            enabled: !busy,
                            autocorrect: false,
                            enableSuggestions: false,
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _haWindDirCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Wind direction entity (optional)',
                              hintText: 'sensor.true_wind_direction',
                            ),
                            enabled: !busy,
                            autocorrect: false,
                            enableSuggestions: false,
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _haDepthCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Depth entity (optional)',
                              hintText: 'sensor.water_depth',
                            ),
                            enabled: !busy,
                            autocorrect: false,
                            enableSuggestions: false,
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              OutlinedButton.icon(
                                onPressed: busy
                                    ? null
                                    : () => _testHa(remote: false),
                                icon: _status == _Status.testingHa
                                    ? const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                            strokeWidth: 2),
                                      )
                                    : const Icon(Icons.home_outlined),
                                label: const Text('Test HA local'),
                              ),
                              OutlinedButton.icon(
                                onPressed:
                                    busy ? null : () => _testHa(remote: true),
                                icon: const Icon(Icons.public),
                                label: const Text('Test HA internet'),
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
