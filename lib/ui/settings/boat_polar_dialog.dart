import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/di.dart';
import '../../models/models.dart';

/// #236: manual boat polar table entry — foundation for weather routing
/// (#238). No privacy/sync-gating like `LlmApiKeyDialog`'s keys; polar data
/// is pushed/pulled plainly like any other boat field.
class BoatPolarDialog extends ConsumerStatefulWidget {
  final Boat boat;

  const BoatPolarDialog({super.key, required this.boat});

  @override
  ConsumerState<BoatPolarDialog> createState() => _BoatPolarDialogState();
}

class _BoatPolarDialogState extends ConsumerState<BoatPolarDialog> {
  late List<PolarPoint> _rows;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _rows = [...widget.boat.polar];
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
                'along a route.',
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
          onPressed: _saving ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _saving ? null : _save,
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
