import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../components/title_tile.dart';
import '../components/common_drawer.dart';
import '../components/main_list_tile.dart';
import '../../core/di.dart';
import '../../core/colors.dart';
import '../../core/units.dart';
import '../../models/models.dart';
import '../../services/location_service.dart';
import '../../services/revenuecat_service.dart';

final captainLogsProvider = StreamProvider<List<CaptainLogEntry>>((ref) {
  final repository = ref.watch(captainLogRepositoryProvider);
  return repository.watchLogs();
});

class LogbookScreen extends ConsumerStatefulWidget {
  const LogbookScreen({super.key});

  @override
  ConsumerState<LogbookScreen> createState() => _LogbookScreenState();
}

class _LogbookScreenState extends ConsumerState<LogbookScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isProAsync = ref.watch(isProProvider);
    final logsAsync = ref.watch(captainLogsProvider);

    return Scaffold(
      body: SafeArea(
        child: Builder(
          builder: (context) => Column(
            children: [
              TitleTile(
                title: "Captain's Log",
                onMenuPressed: () => Scaffold.of(context).openEndDrawer(),
              ),
              MainListSearchBar(
                controller: _searchController,
                hintText: 'Search log entries...',
                onChanged: (v) => setState(() => _searchQuery = v),
              ),
              Expanded(
                child: isProAsync.when(
                  data: (isPro) => logsAsync.when(
                    data: (logs) {
                      // Filter for free users: only last 7 days
                      final filteredLogs = isPro
                          ? logs
                          : logs.where((log) {
                              final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));
                              return log.logDate.isAfter(sevenDaysAgo);
                            }).toList();

                      // Apply search filter
                      final searchFilteredLogs = filteredLogs.where((log) {
                        if (_searchQuery.isNotEmpty) {
                          final notes = log.notes?.toLowerCase() ?? '';
                          final weather = log.weather?.toLowerCase() ?? '';
                          return notes.contains(_searchQuery.toLowerCase()) ||
                                 weather.contains(_searchQuery.toLowerCase());
                        }
                        return true;
                      }).toList();

                      if (searchFilteredLogs.isEmpty) {
                        return const Center(child: Text('No log entries'));
                      }

                      return GridView.builder(
                        padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 0.78,
                          mainAxisSpacing: 10,
                          crossAxisSpacing: 10,
                        ),
                        itemCount: searchFilteredLogs.length,
                        itemBuilder: (context, index) {
                          final log = searchFilteredLogs[index];
                          final dateStr =
                              log.logDate.toString().split(' ').first;
                          return MainListTile(
                            onTap: isPro
                                ? () => _showLogDetail(context, log)
                                : () => ScaffoldMessenger.of(context)
                                    .showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                          'Log details require Pro subscription'),
                                    ),
                                  ),
                            header: MainListTile.iconHeader(
                              icon: Icons.book_outlined,
                              iconColor: SisuColors.incompleteBackground,
                            ),
                            title: log.notes?.trim().isNotEmpty == true
                                ? log.notes!.trim()
                                : 'Log entry',
                            tags: [
                              if (log.weather != null &&
                                  log.weather!.isNotEmpty)
                                log.weather!,
                            ],
                            tagColor: SisuColors.incompleteBackground,
                            metaLine: dateStr,
                            badges: [
                              if (!isPro) 'Pro to edit',
                            ],
                          );
                        },
                      );
                    },
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (e, _) => Center(child: Text('Error: $e')),
                  ),
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (_, _) => const Center(
                      child: Text('Error loading subscription status')),
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          final isPro = ref.read(isProProvider).value ?? false;
          if (isPro) {
            _showAddEditDialog(context);
          } else {
            _showProRequiredDialog(context);
          }
        },
        child: const Icon(Icons.add),
      ),
      endDrawer: _buildEndDrawer(),
    );
  }

  void _showProRequiredDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Sisu Mate Pro Required'),
        content: const Text(
            "Keeping a Captain's Log is a Pro feature. Upgrade to add and edit log entries."),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              RevenueCatService().showPaywall(context);
            },
            child: const Text('Upgrade to Pro'),
          ),
        ],
      ),
    );
  }

  void _showAddEditDialog(BuildContext context, {CaptainLogEntry? existing}) {
    final messenger = ScaffoldMessenger.of(context);
    // Carry-forward source: the most recent entry, only relevant when adding
    // a new one — never for edit (existing already has its own values).
    final logs = ref.read(captainLogsProvider).asData?.value ?? const [];
    final previousEntry = existing == null && logs.isNotEmpty ? logs.first : null;
    showDialog<void>(
      context: context,
      builder: (_) => AddEditCaptainLogDialog(
        existing: existing,
        previousEntry: previousEntry,
        onSave: (entry) async {
          final repo = ref.read(captainLogRepositoryProvider);
          if (existing == null) {
            await repo.addLog(entry);
          } else {
            await repo.updateLog(entry);
          }
          messenger.showSnackBar(
            SnackBar(
                content: Text(existing == null
                    ? 'Log entry added'
                    : 'Log entry updated')),
          );
        },
      ),
    );
  }

  Widget _buildEndDrawer() {
    return Drawer(
      child: SafeArea(
        child: Consumer(
          builder: (context, ref, child) => Column(
            children: [
              DrawerHeaderWidget(title: 'Filters & Options'),
              const Divider(),

              // Search
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: TextField(
                  controller: _searchController,
                  decoration: const InputDecoration(
                    hintText: 'Search logs...',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                ),
              ),
              const Divider(),

              SectionHeader(title: 'Options'),
              DataManagementSection(),
              ProUpgradeSection(),
              AboutSection(),

              const Spacer(),
              DrawerFooter(),
            ],
          ),
        ),
      ),
    );
  }

  void _showLogDetail(BuildContext context, CaptainLogEntry log) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Log Entry - ${log.logDate.toString().split(' ')[0]}'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (log.notes != null) ...[
                const Text('Notes:', style: TextStyle(fontWeight: FontWeight.bold)),
                Text(log.notes!),
                const SizedBox(height: 8),
              ],
              if (log.weather != null) ...[
                const Text('Weather:', style: TextStyle(fontWeight: FontWeight.bold)),
                Text(log.weather!),
                const SizedBox(height: 8),
              ],
              if (log.windSpeedKt != null) ...[
                const Text('Wind:', style: TextStyle(fontWeight: FontWeight.bold)),
                Text('${log.windSpeedKt} knots ${log.windDir ?? ""}'),
                const SizedBox(height: 8),
              ],
              if (log.positionLat != null && log.positionLng != null) ...[
                const Text('Position:', style: TextStyle(fontWeight: FontWeight.bold)),
                Text('${log.positionLat}, ${log.positionLng}'),
                const SizedBox(height: 8),
              ],
              if (log.sogKt != null || log.cogDeg != null) ...[
                const Text('SOG / COG:', style: TextStyle(fontWeight: FontWeight.bold)),
                Text(
                  '${log.sogKt != null ? '${log.sogKt!.toStringAsFixed(1)} kt' : '—'} / '
                  '${log.cogDeg != null ? '${log.cogDeg!.toStringAsFixed(0)}°' : '—'}',
                ),
                const SizedBox(height: 8),
              ],
              if (log.barometricPressureHpa != null || log.seaState != null) ...[
                const Text('Pressure / Sea state:', style: TextStyle(fontWeight: FontWeight.bold)),
                Text(
                  '${log.barometricPressureHpa != null ? '${log.barometricPressureHpa!.toStringAsFixed(0)} hPa' : '—'} / '
                  '${log.seaState ?? '—'}',
                ),
                const SizedBox(height: 8),
              ],
              if (log.engineHours != null || log.fuelLevelPercent != null) ...[
                const Text('Engine hrs / Fuel:', style: TextStyle(fontWeight: FontWeight.bold)),
                Text(
                  '${log.engineHours != null ? log.engineHours!.toStringAsFixed(1) : '—'} / '
                  '${log.fuelLevelPercent != null ? '${log.fuelLevelPercent!.toStringAsFixed(0)}%' : '—'}',
                ),
                const SizedBox(height: 8),
              ],
              if (log.watchCrew.isNotEmpty) ...[
                const Text('On watch:', style: TextStyle(fontWeight: FontWeight.bold)),
                Text(log.watchCrew.join(', ')),
                const SizedBox(height: 8),
              ],
              if (log.crewOnBoard.isNotEmpty) ...[
                const Text('Crew:', style: TextStyle(fontWeight: FontWeight.bold)),
                Text(log.crewOnBoard.join(', ')),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await ref.read(captainLogRepositoryProvider).deleteLog(log);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _showAddEditDialog(context, existing: log);
            },
            child: const Text('Edit'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

/// Add / edit dialog for a Captain's Log entry (public for widget tests).
class AddEditCaptainLogDialog extends StatefulWidget {
  final CaptainLogEntry? existing;
  /// Most recent prior entry, for carry-forward pre-fill on a *new* entry
  /// only (#213) — never passed when editing. Only fields that make sense
  /// to repeat (crew) are pre-filled; position/SOG/COG must only ever come
  /// from an explicit "Use GPS" tap, never stale carry-forward.
  final CaptainLogEntry? previousEntry;
  final Future<void> Function(CaptainLogEntry entry) onSave;
  final LocationService? locationService;

  const AddEditCaptainLogDialog({
    super.key,
    this.existing,
    this.previousEntry,
    required this.onSave,
    this.locationService,
  });

  @override
  State<AddEditCaptainLogDialog> createState() =>
      _AddEditCaptainLogDialogState();
}

class _AddEditCaptainLogDialogState extends State<AddEditCaptainLogDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _notesCtrl;
  late final TextEditingController _weatherCtrl;
  late final TextEditingController _windSpeedCtrl;
  late final TextEditingController _windDirCtrl;
  late final TextEditingController _latCtrl;
  late final TextEditingController _lngCtrl;
  late final TextEditingController _sogCtrl;
  late final TextEditingController _cogCtrl;
  late final TextEditingController _pressureCtrl;
  late final TextEditingController _seaStateCtrl;
  late final TextEditingController _watchCrewCtrl;
  late final TextEditingController _engineHoursCtrl;
  late final TextEditingController _fuelLevelCtrl;
  late final TextEditingController _crewCtrl;
  late final LocationService _locationService =
      widget.locationService ?? const LocationService();
  late DateTime _date;
  bool _locating = false;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    final prev = widget.previousEntry;
    _notesCtrl = TextEditingController(text: e?.notes ?? '');
    _weatherCtrl = TextEditingController(text: e?.weather ?? '');
    _windSpeedCtrl =
        TextEditingController(text: e?.windSpeedKt?.toString() ?? '');
    _windDirCtrl = TextEditingController(text: e?.windDir ?? '');
    _latCtrl = TextEditingController(text: e?.positionLat?.toString() ?? '');
    _lngCtrl = TextEditingController(text: e?.positionLng?.toString() ?? '');
    _sogCtrl = TextEditingController(text: e?.sogKt?.toString() ?? '');
    _cogCtrl = TextEditingController(text: e?.cogDeg?.toString() ?? '');
    _pressureCtrl = TextEditingController(
        text: e?.barometricPressureHpa?.toString() ?? '');
    _seaStateCtrl = TextEditingController(text: e?.seaState ?? '');
    _engineHoursCtrl =
        TextEditingController(text: e?.engineHours?.toString() ?? '');
    _fuelLevelCtrl =
        TextEditingController(text: e?.fuelLevelPercent?.toString() ?? '');
    // Carry-forward: only on a new entry (e == null), and only for fields
    // that are sensible to repeat — crew tends to stay the same leg to leg.
    _crewCtrl = TextEditingController(
        text: e?.crewOnBoard.join(', ') ??
            prev?.crewOnBoard.join(', ') ??
            '');
    _watchCrewCtrl = TextEditingController(
        text:
            e?.watchCrew.join(', ') ?? prev?.watchCrew.join(', ') ?? '');
    _date = e?.logDate ?? DateTime.now();
  }

  @override
  void dispose() {
    _notesCtrl.dispose();
    _weatherCtrl.dispose();
    _windSpeedCtrl.dispose();
    _windDirCtrl.dispose();
    _latCtrl.dispose();
    _lngCtrl.dispose();
    _sogCtrl.dispose();
    _cogCtrl.dispose();
    _pressureCtrl.dispose();
    _seaStateCtrl.dispose();
    _watchCrewCtrl.dispose();
    _engineHoursCtrl.dispose();
    _fuelLevelCtrl.dispose();
    _crewCtrl.dispose();
    super.dispose();
  }

  String? _validateOptionalNumber(String? v) {
    if (v == null || v.isEmpty) return null;
    return double.tryParse(v) == null ? 'Invalid number' : null;
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _date = picked);
  }

  /// #213: fills Lat/Lng and, when the fix reports them, SOG/COG from one
  /// GPS position. Zero `speedAccuracy`/`headingAccuracy` means the device
  /// didn't actually report that value (geolocator default), not a real
  /// zero reading — those fields are left for manual entry in that case.
  Future<void> _useGps() async {
    if (_locating) return;
    setState(() => _locating = true);
    try {
      final result = await _locationService.getCurrentPosition();
      if (!mounted) return;
      if (!result.isSuccess) {
        final message = switch (result.failureReason) {
          LocationFailureReason.serviceDisabled =>
            'Turn on location services to use GPS',
          LocationFailureReason.permissionDenied =>
            'Location permission denied — enter coordinates manually',
          _ => 'Could not get location: ${result.error}',
        };
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(message)));
        return;
      }
      final pos = result.position!;
      setState(() {
        _latCtrl.text = pos.latitude.toStringAsFixed(4);
        _lngCtrl.text = pos.longitude.toStringAsFixed(4);
        if (pos.speedAccuracy > 0) {
          _sogCtrl.text =
              (pos.speed / UnitConverter.msPerKnot).toStringAsFixed(1);
        }
        if (pos.headingAccuracy > 0) {
          _cogCtrl.text = pos.heading.toStringAsFixed(0);
        }
      });
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final entry = widget.existing ??
        (CaptainLogEntry()
          ..supabaseId = 'log_${DateTime.now().millisecondsSinceEpoch}'
          ..boatSupabaseId = '00000000-0000-0000-0000-000000000000');
    entry
      ..logDate = _date
      ..notes = _notesCtrl.text.isEmpty ? null : _notesCtrl.text
      ..weather = _weatherCtrl.text.isEmpty ? null : _weatherCtrl.text
      ..windSpeedKt = int.tryParse(_windSpeedCtrl.text)
      ..windDir = _windDirCtrl.text.isEmpty ? null : _windDirCtrl.text
      ..positionLat = double.tryParse(_latCtrl.text)
      ..positionLng = double.tryParse(_lngCtrl.text)
      ..sogKt = double.tryParse(_sogCtrl.text)
      ..cogDeg = double.tryParse(_cogCtrl.text)
      ..barometricPressureHpa = double.tryParse(_pressureCtrl.text)
      ..seaState = _seaStateCtrl.text.isEmpty ? null : _seaStateCtrl.text
      ..watchCrew = _watchCrewCtrl.text
          .split(',')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList()
      ..engineHours = double.tryParse(_engineHoursCtrl.text)
      ..fuelLevelPercent = double.tryParse(_fuelLevelCtrl.text)
      ..crewOnBoard = _crewCtrl.text
          .split(',')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();
    Navigator.of(context).pop();
    widget.onSave(entry);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.existing == null ? 'New Log Entry' : 'Edit Log Entry'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                        'Date: ${_date.toIso8601String().split('T').first}'),
                  ),
                  TextButton(
                      onPressed: _pickDate, child: const Text('Change')),
                ],
              ),
              TextFormField(
                controller: _notesCtrl,
                decoration: const InputDecoration(labelText: 'Notes'),
                maxLines: 3,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _weatherCtrl,
                decoration: const InputDecoration(labelText: 'Weather'),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _windSpeedCtrl,
                      decoration:
                          const InputDecoration(labelText: 'Wind (kt)'),
                      keyboardType: TextInputType.number,
                      validator: _validateOptionalNumber,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      controller: _windDirCtrl,
                      decoration:
                          const InputDecoration(labelText: 'Wind dir'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: OutlinedButton.icon(
                  onPressed: _locating ? null : _useGps,
                  icon: Icon(
                    _locating ? Icons.hourglass_top : Icons.my_location,
                    size: 18,
                  ),
                  label: const Text('Use GPS'),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _latCtrl,
                      decoration: const InputDecoration(labelText: 'Latitude'),
                      keyboardType: const TextInputType.numberWithOptions(
                          decimal: true, signed: true),
                      validator: _validateOptionalNumber,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      controller: _lngCtrl,
                      decoration:
                          const InputDecoration(labelText: 'Longitude'),
                      keyboardType: const TextInputType.numberWithOptions(
                          decimal: true, signed: true),
                      validator: _validateOptionalNumber,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _sogCtrl,
                      decoration: const InputDecoration(labelText: 'SOG (kt)'),
                      keyboardType: const TextInputType.numberWithOptions(
                          decimal: true),
                      validator: _validateOptionalNumber,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      controller: _cogCtrl,
                      decoration:
                          const InputDecoration(labelText: 'COG (°true)'),
                      keyboardType: const TextInputType.numberWithOptions(
                          decimal: true),
                      validator: _validateOptionalNumber,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _pressureCtrl,
                      decoration:
                          const InputDecoration(labelText: 'Pressure (hPa)'),
                      keyboardType: const TextInputType.numberWithOptions(
                          decimal: true),
                      validator: _validateOptionalNumber,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      controller: _seaStateCtrl,
                      decoration:
                          const InputDecoration(labelText: 'Sea state'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _engineHoursCtrl,
                      decoration:
                          const InputDecoration(labelText: 'Engine hrs'),
                      keyboardType: const TextInputType.numberWithOptions(
                          decimal: true),
                      validator: _validateOptionalNumber,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      controller: _fuelLevelCtrl,
                      decoration:
                          const InputDecoration(labelText: 'Fuel level (%)'),
                      keyboardType: const TextInputType.numberWithOptions(
                          decimal: true),
                      validator: _validateOptionalNumber,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _crewCtrl,
                decoration: const InputDecoration(
                  labelText: 'Crew on board',
                  helperText: 'Comma-separated',
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _watchCrewCtrl,
                decoration: const InputDecoration(
                  labelText: 'On watch',
                  helperText: 'Comma-separated — who\'s on duty now',
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel')),
        ElevatedButton(onPressed: _save, child: const Text('Save')),
      ],
    );
  }
}
