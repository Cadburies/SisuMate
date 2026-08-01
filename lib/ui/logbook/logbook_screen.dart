import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../components/title_tile.dart';
import '../components/common_drawer.dart';
import '../components/main_list_tile.dart';
import '../../core/di.dart';
import '../../core/colors.dart';
import '../../models/models.dart';
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
    showDialog<void>(
      context: context,
      builder: (_) => AddEditCaptainLogDialog(
        existing: existing,
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
  final Future<void> Function(CaptainLogEntry entry) onSave;

  const AddEditCaptainLogDialog({
    super.key,
    this.existing,
    required this.onSave,
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
  late final TextEditingController _crewCtrl;
  late DateTime _date;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _notesCtrl = TextEditingController(text: e?.notes ?? '');
    _weatherCtrl = TextEditingController(text: e?.weather ?? '');
    _windSpeedCtrl =
        TextEditingController(text: e?.windSpeedKt?.toString() ?? '');
    _windDirCtrl = TextEditingController(text: e?.windDir ?? '');
    _latCtrl = TextEditingController(text: e?.positionLat?.toString() ?? '');
    _lngCtrl = TextEditingController(text: e?.positionLng?.toString() ?? '');
    _crewCtrl = TextEditingController(text: e?.crewOnBoard.join(', ') ?? '');
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
              TextFormField(
                controller: _crewCtrl,
                decoration: const InputDecoration(
                  labelText: 'Crew on board',
                  helperText: 'Comma-separated',
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
