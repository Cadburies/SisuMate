import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/di.dart';
import '../../models/models.dart';

/// #236 / #274: manual boat polar table + under-sail sample count and
/// offline/LLM polar improve.
class BoatPolarDialog extends ConsumerStatefulWidget {
  final Boat boat;

  const BoatPolarDialog({super.key, required this.boat});

  @override
  ConsumerState<BoatPolarDialog> createState() => _BoatPolarDialogState();
}

class _BoatPolarDialogState extends ConsumerState<BoatPolarDialog> {
  late List<PolarPoint> _rows;
  bool _saving = false;
  bool _improving = false;
  int _sampleCount = 0;
  String? _statusMsg;

  @override
  void initState() {
    super.initState();
    _rows = [...widget.boat.polar];
    _loadSampleCount();
  }

  Future<void> _loadSampleCount() async {
    final id = widget.boat.supabaseId;
    if (id.isEmpty) return;
    final n =
        await ref.read(sailingPolarCollectorProvider).sampleCount(id);
    if (mounted) setState(() => _sampleCount = n);
  }

  Future<void> _improvePolar({required bool tryLlm}) async {
    setState(() {
      _improving = true;
      _statusMsg = null;
    });
    final svc = ref.read(polarLlmImproveServiceProvider);
    final result = await svc.improve(boat: widget.boat, tryLlm: tryLlm);
    if (!mounted) return;
    setState(() {
      _improving = false;
      _statusMsg = result.message;
      if (result.ok && result.polar != null) {
        _rows = [...result.polar!];
      }
    });
    await _loadSampleCount();
  }

  void _addRow() {
    setState(() =>
        _rows.add(const PolarPoint(twaDeg: 0, twsKt: 0, boatSpeedKt: 0)));
  }

  void _removeRow(int i) => setState(() => _rows.removeAt(i));

  void _updateRow(int i, {double? twa, double? tws, double? speed}) {
    final r = _rows[i];
    setState(() {
      _rows[i] = PolarPoint(
        twaDeg: twa ?? r.twaDeg,
        twsKt: tws ?? r.twsKt,
        boatSpeedKt: speed ?? r.boatSpeedKt,
      );
    });
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final boat = widget.boat..polar = _rows;
    final repo = ref.read(boatRepositoryProvider);
    try {
      await repo.updateBoat(boat);
    } finally {
      if (mounted) Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Boat polar data'),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Boat speed (kt) at a given true wind angle (deg — 0 = head '
                'to wind, 180 = dead downwind) and true wind speed (kt). '
                'Used for a more realistic ETA once wind data is available '
                'along a route.\n\n'
                'While sailing (instruments online, engines not showing revs), '
                'the app stores samples in the background (no Anchor Alarm '
                'required). Prefers speed-through-water (STW) over SOG. '
                'Anonymized metrics sync when Pro/online. Improve offline '
                'with bucket stats, or with AI when a boat LLM key is set.',
              ),
              const SizedBox(height: 8),
              Text(
                'Under-sail samples stored: $_sampleCount',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              if (_statusMsg != null) ...[
                const SizedBox(height: 4),
                Text(
                  _statusMsg!,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  OutlinedButton.icon(
                    onPressed: (_improving || _saving)
                        ? null
                        : () => _improvePolar(tryLlm: false),
                    icon: _improving
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.analytics_outlined, size: 18),
                    label: const Text('Improve offline'),
                  ),
                  FilledButton.tonalIcon(
                    onPressed: (_improving || _saving)
                        ? null
                        : () => _improvePolar(tryLlm: true),
                    icon: const Icon(Icons.auto_awesome, size: 18),
                    label: const Text('Improve with AI'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              for (var i = 0; i < _rows.length; i++) _row(i),
              TextButton.icon(
                onPressed: _addRow,
                icon: const Icon(Icons.add),
                label: const Text('Add row'),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: (_saving || _improving)
              ? null
              : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: (_saving || _improving) ? null : _save,
          child: _saving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Save'),
        ),
      ],
    );
  }

  Widget _row(int i) {
    final r = _rows[i];
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: TextFormField(
              key: ValueKey('twa_$i'),
              initialValue: r.twaDeg.toStringAsFixed(0),
              decoration: const InputDecoration(
                labelText: 'TWA°',
                isDense: true,
                border: OutlineInputBorder(),
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              onChanged: (v) {
                final n = double.tryParse(v);
                if (n != null) _updateRow(i, twa: n);
              },
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: TextFormField(
              key: ValueKey('tws_$i'),
              initialValue: r.twsKt.toStringAsFixed(0),
              decoration: const InputDecoration(
                labelText: 'TWS kt',
                isDense: true,
                border: OutlineInputBorder(),
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              onChanged: (v) {
                final n = double.tryParse(v);
                if (n != null) _updateRow(i, tws: n);
              },
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: TextFormField(
              key: ValueKey('speed_$i'),
              initialValue: r.boatSpeedKt.toStringAsFixed(1),
              decoration: const InputDecoration(
                labelText: 'Speed kt',
                isDense: true,
                border: OutlineInputBorder(),
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              onChanged: (v) {
                final n = double.tryParse(v);
                if (n != null) _updateRow(i, speed: n);
              },
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () => _removeRow(i),
          ),
        ],
      ),
    );
  }
}
