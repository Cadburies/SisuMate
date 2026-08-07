import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../components/title_tile.dart';
import '../components/main_list_tile.dart';
import '../components/common_drawer.dart';
import '../components/import_export.dart';
import '../components/record_detail_screen.dart';
import '../../core/app_router.dart';
import '../../core/di.dart';
import '../../core/units.dart';
import '../../models/models.dart';
import '../../services/fuel_burn_estimator.dart';
import '../../services/revenuecat_service.dart';
import '../../services/import_service.dart';

final fuelLogEntriesProvider = StreamProvider<List<FuelLogEntry>>((ref) {
  return ref.watch(fuelLogRepositoryProvider).watchEntries();
});

const _entryTypes = ['Fuel', 'Water'];

IconData _iconForType(String type) =>
    type == 'Water' ? Icons.water_drop_outlined : Icons.local_gas_station_outlined;

String _formatUsd(double amount) => '\$${amount.toStringAsFixed(2)}';

String _formatDate(DateTime d) => d.toString().split(' ')[0];

/// List/detail title: notes when present (unique for LT2 + user scannability),
/// otherwise type (Fuel/Water).
String _entryListTitle(FuelLogEntry e) {
  final n = e.notes?.trim();
  if (n != null && n.isNotEmpty) return n;
  return e.type;
}

class FuelScreen extends ConsumerWidget {
  const FuelScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isProAsync = ref.watch(isProProvider);
    final entriesAsync = ref.watch(fuelLogEntriesProvider);
    final unitSystem = ref.watch(unitSystemProvider);
    final isPro = isProAsync.value ?? false;
    final entries = entriesAsync.value ?? const <FuelLogEntry>[];

    return Scaffold(
      body: SafeArea(
        child: Builder(
          builder: (context) => Column(
            children: [
              TitleTile(
                title: 'Fuel & Water Log',
                onMenuPressed: () => Scaffold.of(context).openEndDrawer(),
                actionsBuilder: (color) => [
                  IconButton(
                    icon: Icon(Icons.import_export, color: color),
                    tooltip: 'Import / Export',
                    onPressed: () => showImportExportSheet(
                      context,
                      ModuleImportExport(
                        kind: ImportService.kindFuelLog,
                        label: 'Fuel & Water',
                        fileBaseName: 'sisu_fuel',
                        exportCurrent: () async =>
                            ImportService.exportFuelLogs(
                          entries,
                          unitSystem: ref.read(unitSystemProvider),
                        ),
                        persist: (batch) async {
                          final repo = ref.read(fuelLogRepositoryProvider);
                          for (final e in batch.fuelLogs) {
                            await repo.addEntry(e);
                          }
                          return ImportPersistResult.allInserted(
                              batch.fuelLogs.length);
                        },
                      ),
                      isPro: isPro,
                      onProRequired: () => _showProRequiredDialog(context),
                              ref: ref,
                    ),
                  ),
                ],
              ),
              Expanded(
                child: entriesAsync.when(
                  data: (entries) {
                    if (entries.isEmpty) {
                      return const Center(child: Text('No entries yet'));
                    }
                    return Column(
                      children: [
                        _SummaryStrip(entries: entries, unitSystem: unitSystem),
                        _BurnEstimateStrip(
                            entries: entries, unitSystem: unitSystem),
                        Expanded(
                          child: GridView.builder(
                            padding:
                                const EdgeInsets.fromLTRB(12, 4, 12, 12),
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              childAspectRatio: 0.78,
                              mainAxisSpacing: 10,
                              crossAxisSpacing: 10,
                            ),
                            itemCount: entries.length,
                            itemBuilder: (context, i) {
                              final entry = entries[i];
                              final isFuel = entry.type != 'Water';
                              final listTitle = _entryListTitle(entry);
                              final notesAsTitle = listTitle != entry.type;
                              return MainListTile(
                                onTap: () => _showDetail(
                                    context, ref, entry, isPro),
                                header: MainListTile.iconHeader(
                                  icon: _iconForType(entry.type),
                                  iconColor: isFuel
                                      ? Colors.amber.shade800
                                      : Colors.blue,
                                ),
                                title: listTitle,
                                tags: [
                                  if (notesAsTitle) entry.type,
                                  UnitConverter.formatLiters(
                                      entry.liters, unitSystem),
                                ],
                                tagColor: isFuel
                                    ? Colors.amber.shade800
                                    : Colors.blue,
                                countLine: entry.totalCost > 0
                                    ? _formatUsd(entry.totalCost)
                                    : null,
                                metaLine: _formatDate(entry.date),
                                badges: [
                                  if (entry.pricePerLiter > 0)
                                    UnitConverter.formatPricePerVolume(
                                      entry.pricePerLiter,
                                      unitSystem,
                                    ),
                                ],
                              );
                            },
                          ),
                        ),
                      ],
                    );
                  },
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Center(child: Text('Error: $e')),
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => isPro
            ? _showAddEditDialog(context, ref)
            : _showProRequiredDialog(context),
        child: const Icon(Icons.add),
      ),
      endDrawer: _buildEndDrawer(),
    );
  }

  Widget _buildEndDrawer() {
    return Drawer(
      child: SafeArea(
        child: Consumer(
          builder: (context, ref, child) => Column(
            children: [
              DrawerHeaderWidget(title: 'Menu'),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      const Divider(),
                      SectionHeader(title: 'Account'),
                      AccountSection(),
                      const Divider(),
                      SectionHeader(title: 'Data Management'),
                      DataManagementSection(),
                      ProUpgradeSection(),
                      AboutSection(),
                    ],
                  ),
                ),
              ),
              DrawerFooter(),
            ],
          ),
        ),
      ),
    );
  }

  void _showProRequiredDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Sisu Mate Pro Required'),
        content: const Text(
            'Logging fuel and water is a Pro feature. Upgrade to unlock the Fuel & Water Log.'),
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

  void _showDetail(
      BuildContext context, WidgetRef ref, FuelLogEntry entry, bool isPro) {
    final entries =
        ref.read(fuelLogEntriesProvider).asData?.value ?? [entry];
    final unitSystem = ref.read(unitSystemProvider);
    final volLabel = UnitConverter.fuelVolumeLabel(unitSystem);
    final index = entries.indexWhere((e) => e.supabaseId == entry.supabaseId);
    final list = index < 0 ? [entry] : entries;
    final start = index < 0 ? 0 : index;

    context.push(
      AppRoutes.fuelDetail,
      extra: RecordDetailArgs(
          itemCount: list.length,
          initialIndex: start,
          canEdit: isPro,
          titleForIndex: (i) {
            final e = list[i];
            final vol = UnitConverter.formatLiters(e.liters, unitSystem);
            final n = e.notes?.trim();
            if (n != null && n.isNotEmpty) return '$n • $vol';
            return '${e.type} • $vol';
          },
          historyForIndex: (i) => [
            'Logged: ${_formatDate(list[i].date)}',
            'Last modified: ${list[i].lastModified.toLocal()}',
          ],
          fieldsForIndex: (i) {
            final e = list[i];
            return [
              RecordField(
                  key: 'type',
                  label: 'Type',
                  value: e.type,
                  options: _entryTypes),
              RecordField(
                  key: 'date',
                  label: 'Date',
                  value: e.date.toIso8601String(),
                  isDate: true),
              RecordField(
                  key: 'volume',
                  label: 'Volume ($volLabel)',
                  value: UnitConverter.formatNumber(
                      UnitConverter.litersToDisplay(e.liters, unitSystem)),
                  isNumber: true),
              RecordField(
                  key: 'pricePerVolume',
                  label:
                      'Price per ${UnitConverter.fuelPriceVolumeWord(unitSystem)} (USD)',
                  value: UnitConverter.formatNumber(
                    UnitConverter.pricePerLiterToDisplay(
                        e.pricePerLiter, unitSystem),
                  ),
                  isNumber: true),
              RecordField(
                  key: 'notes',
                  label: 'Notes',
                  value: e.notes ?? '',
                  multiline: true),
              RecordField(
                  key: 'lastModified',
                  label: 'Last modified',
                  value: e.lastModified.toIso8601String()),
            ];
          },
          onSave: (i, values) async {
            final e = list[i];
            final displayVol =
                double.tryParse(values['volume'] ?? '') ??
                    UnitConverter.litersToDisplay(e.liters, unitSystem);
            final liters =
                UnitConverter.displayVolumeToLiters(displayVol, unitSystem);
            final displayPrice = double.tryParse(
                    values['pricePerVolume'] ?? '') ??
                UnitConverter.pricePerLiterToDisplay(
                    e.pricePerLiter, unitSystem);
            final ppl = UnitConverter.displayPriceToPerLiter(
                displayPrice, unitSystem);
            e
              ..type = values['type'] ?? e.type
              ..date = DateTime.tryParse(values['date'] ?? '') ?? e.date
              ..liters = liters
              ..pricePerLiter = ppl
              ..totalCost = liters * ppl
              ..notes = (values['notes'] ?? '').isEmpty ? null : values['notes'];
            await ref.read(fuelLogRepositoryProvider).updateEntry(e);
          },
          onDelete: isPro
              ? (i) =>
                  ref.read(fuelLogRepositoryProvider).deleteEntry(list[i])
              : null,
      ),
    );
  }

  void _showAddEditDialog(BuildContext context, WidgetRef ref,
      {FuelLogEntry? existing}) {
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final unitSystem = ref.read(unitSystemProvider);
    showDialog<void>(
      context: context,
      builder: (_) => AddEditFuelEntryDialog(
        existing: existing,
        unitSystem: unitSystem,
        onSave: (entry) async {
          final repo = ref.read(fuelLogRepositoryProvider);
          if (existing == null) {
            await repo.addEntry(entry);
          } else {
            await repo.updateEntry(entry);
          }
          navigator.pop();
          messenger.showSnackBar(
              SnackBar(content: Text('${entry.type} entry saved')));
        },
      ),
    );
  }
}

class _SummaryStrip extends StatelessWidget {
  final List<FuelLogEntry> entries;
  final UnitSystem unitSystem;
  const _SummaryStrip({required this.entries, required this.unitSystem});

  @override
  Widget build(BuildContext context) {
    double fuelLiters = 0, waterLiters = 0, totalCost = 0;
    for (final e in entries) {
      if (e.type == 'Water') {
        waterLiters += e.liters;
      } else {
        fuelLiters += e.liters;
      }
      totalCost += e.totalCost;
    }
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _SummaryItem(
              label: 'Fuel',
              value: UnitConverter.formatLiters(fuelLiters, unitSystem)),
          _SummaryItem(
              label: 'Water',
              value: UnitConverter.formatLiters(waterLiters, unitSystem)),
          _SummaryItem(label: 'Spend (USD)', value: _formatUsd(totalCost)),
        ],
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  final String label;
  final String value;
  const _SummaryItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(value,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}

/// BAI4: burn rate + ETA empty from fill history (optional hours/NM fields).
class _BurnEstimateStrip extends StatefulWidget {
  final List<FuelLogEntry> entries;
  final UnitSystem unitSystem;
  const _BurnEstimateStrip({
    required this.entries,
    required this.unitSystem,
  });

  @override
  State<_BurnEstimateStrip> createState() => _BurnEstimateStripState();
}

class _BurnEstimateStripState extends State<_BurnEstimateStrip> {
  final _hoursCtrl = TextEditingController();
  final _nmCtrl = TextEditingController();
  bool _expanded = false;

  @override
  void dispose() {
    _hoursCtrl.dispose();
    _nmCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hours = double.tryParse(_hoursCtrl.text.trim());
    final nm = double.tryParse(_nmCtrl.text.trim());
    final estimates = const FuelBurnEstimator().estimate(
      entries: widget.entries,
      hoursMotored: hours != null && hours > 0 ? hours : null,
      distanceNm: nm != null && nm > 0 ? nm : null,
    );
    if (estimates.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final urgent = estimates.any(
        (e) => e.daysUntilEmpty != null && e.daysUntilEmpty! <= 3);

    return Material(
      color: urgent
          ? theme.colorScheme.errorContainer.withValues(alpha: 0.35)
          : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.7),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 6, 12, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.hourglass_bottom_outlined,
                  size: 18,
                  color: urgent
                      ? theme.colorScheme.error
                      : theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Burn & range',
                    style: theme.textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
                TextButton(
                  onPressed: () => setState(() => _expanded = !_expanded),
                  child: Text(_expanded ? 'Hide opts' : 'Hours / NM'),
                ),
              ],
            ),
            if (_expanded) ...[
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _hoursCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Hours motored',
                        isDense: true,
                        border: OutlineInputBorder(),
                      ),
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _nmCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Distance (NM)',
                        isDense: true,
                        border: OutlineInputBorder(),
                      ),
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
            ],
            for (final e in estimates)
              Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Text(
                  _formatEstimate(e, widget.unitSystem),
                  style: theme.textTheme.bodySmall,
                ),
              ),
            Text(
              'Assumes top-ups to full; capacity = largest fill unless overridden.',
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatEstimate(TankBurnEstimate e, UnitSystem system) {
    // Prefer unit-aware remaining / rates when available.
    final parts = <String>[e.type];
    if (e.litersPerDay != null) {
      parts.add(
          '${UnitConverter.formatLiters(e.litersPerDay!, system)}/day');
    }
    if (e.litersPerHour != null) {
      parts.add(
          '${UnitConverter.formatLiters(e.litersPerHour!, system)}/h');
    }
    if (e.litersPerNm != null) {
      parts.add(
          '${UnitConverter.formatLiters(e.litersPerNm!, system)}/NM');
    }
    if (e.estimatedRemainingLiters != null) {
      parts.add(
          '${UnitConverter.formatLiters(e.estimatedRemainingLiters!, system)} est. left');
    } else if (e.sampleFills < 2) {
      // No burn rate yet — remaining is unknown, not full capacity.
      parts.add('unknown — log another fill');
    }
    if (e.daysUntilEmpty != null) {
      if (e.daysUntilEmpty! <= 0) {
        parts.add('empty / fill now');
      } else {
        parts.add('~${e.daysUntilEmpty}d to empty');
      }
    }
    // #294 — remaining range when distance-based burn is known.
    final rangeNm = e.remainingRangeNm;
    if (rangeNm != null) {
      parts.add('~${rangeNm >= 100 ? rangeNm.toStringAsFixed(0) : rangeNm.toStringAsFixed(1)} NM range');
    }
    return parts.join(' · ');
  }
}

class AddEditFuelEntryDialog extends StatefulWidget {
  final FuelLogEntry? existing;
  final UnitSystem unitSystem;
  final void Function(FuelLogEntry) onSave;
  const AddEditFuelEntryDialog({
    super.key,
    this.existing,
    this.unitSystem = UnitSystem.metric,
    required this.onSave,
  });

  @override
  State<AddEditFuelEntryDialog> createState() => AddEditFuelEntryDialogState();
}

class AddEditFuelEntryDialogState extends State<AddEditFuelEntryDialog> {
  final _formKey = GlobalKey<FormState>();
  final _litersCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  String _type = _entryTypes.first;
  DateTime _date = DateTime.now();

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    if (existing != null) {
      _type = _entryTypes.contains(existing.type) ? existing.type : 'Fuel';
      _date = existing.date;
      _litersCtrl.text = UnitConverter.formatNumber(
        UnitConverter.litersToDisplay(existing.liters, widget.unitSystem),
      );
      if (existing.pricePerLiter > 0) {
        _priceCtrl.text = UnitConverter.pricePerLiterToDisplay(
          existing.pricePerLiter,
          widget.unitSystem,
        ).toStringAsFixed(2);
      }
      _notesCtrl.text = existing.notes ?? '';
    }
  }

  @override
  void dispose() {
    _litersCtrl.dispose();
    _priceCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
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

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;
    return AlertDialog(
      title: Text(isEdit ? 'Edit Entry' : 'Add Entry'),
      content: SizedBox(
        width: 400,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  initialValue: _type,
                  decoration: const InputDecoration(labelText: 'Type'),
                  items: _entryTypes
                      .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                      .toList(),
                  onChanged: (v) => setState(() => _type = v ?? _type),
                ),
                const SizedBox(height: 8),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text('Date: ${_formatDate(_date)}'),
                  trailing: TextButton(
                      onPressed: _pickDate, child: const Text('Set')),
                ),
                TextFormField(
                  controller: _litersCtrl,
                  decoration: InputDecoration(
                    labelText:
                        'Volume (${UnitConverter.fuelVolumeLabel(widget.unitSystem)})',
                  ),
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Required';
                    return double.tryParse(v) == null ? 'Invalid number' : null;
                  },
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _priceCtrl,
                  decoration: InputDecoration(
                    labelText:
                        'Price per ${UnitConverter.fuelPriceVolumeWord(widget.unitSystem)} (USD)',
                    helperText: widget.unitSystem == UnitSystem.imperial
                        ? 'Stored as \$/L after conversion'
                        : null,
                  ),
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  validator: (v) {
                    if (v == null || v.isEmpty) return null;
                    return double.tryParse(v) == null ? 'Invalid number' : null;
                  },
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _notesCtrl,
                  decoration: const InputDecoration(labelText: 'Notes'),
                  maxLines: 2,
                ),
              ],
            ),
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

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final displayVol = double.tryParse(_litersCtrl.text) ?? 0;
    final liters =
        UnitConverter.displayVolumeToLiters(displayVol, widget.unitSystem);
    final displayPrice = double.tryParse(_priceCtrl.text) ?? 0;
    final pricePerLiter = UnitConverter.displayPriceToPerLiter(
      displayPrice,
      widget.unitSystem,
    );
    final entry = widget.existing ??
        (FuelLogEntry()
          ..supabaseId = 'fuel_${DateTime.now().millisecondsSinceEpoch}'
          ..boatSupabaseId = '00000000-0000-0000-0000-000000000000');
    entry
      ..type = _type
      ..date = _date
      ..liters = liters
      ..pricePerLiter = pricePerLiter
      ..totalCost = liters * pricePerLiter
      ..notes = _notesCtrl.text.isEmpty ? null : _notesCtrl.text;
    widget.onSave(entry);
  }
}
