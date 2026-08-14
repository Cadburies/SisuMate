import 'dart:io';

import 'package:flutter/material.dart';

import '../../models/models.dart';
import '../components/photo_source_picker.dart';

/// #328 — save / edit a named anchorage (catalog, not the live watch).
class SaveAnchorSpotDialog extends StatefulWidget {
  final AnchorWatch? watch;
  final AnchorSpot? existing;
  final double? depthMeters;

  const SaveAnchorSpotDialog({
    super.key,
    this.watch,
    this.existing,
    this.depthMeters,
  });

  @override
  State<SaveAnchorSpotDialog> createState() => _SaveAnchorSpotDialogState();
}

class _SaveAnchorSpotDialogState extends State<SaveAnchorSpotDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _commentsCtrl;
  late final TextEditingController _amenitiesCtrl;
  late final TextEditingController _dinghyNotesCtrl;
  late final TextEditingController _depthCtrl;

  late String _bottom;
  String? _holding;
  String? _swell;
  String? _dinghy;
  late Set<String> _windSectors;
  String? _photoPath;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _nameCtrl = TextEditingController(text: e?.name ?? '');
    _commentsCtrl = TextEditingController(text: e?.comments ?? '');
    _amenitiesCtrl = TextEditingController(text: e?.amenities ?? '');
    _dinghyNotesCtrl = TextEditingController(text: e?.dinghyNotes ?? '');
    final depth = e?.depthMeters ?? widget.depthMeters;
    _depthCtrl = TextEditingController(
      text: depth == null ? '' : depth.toStringAsFixed(1),
    );
    _bottom = e?.bottom ?? AnchorBottom.unknown;
    _holding = (e?.holdingQuality.isNotEmpty ?? false) ? e!.holdingQuality : null;
    _swell = (e?.swellExposure.isNotEmpty ?? false) ? e!.swellExposure : null;
    _dinghy = (e?.dinghyLanding.isNotEmpty ?? false) ? e!.dinghyLanding : null;
    _windSectors = {...(e?.windProtection ?? const <String>[])};
    _photoPath = e?.photoPath;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _commentsCtrl.dispose();
    _amenitiesCtrl.dispose();
    _dinghyNotesCtrl.dispose();
    _depthCtrl.dispose();
    super.dispose();
  }

  AnchorSpot _buildSpot() {
    final depth = double.tryParse(_depthCtrl.text.trim());
    final watch = widget.watch;
    final existing = widget.existing;
    final spot = existing ??
        (watch != null
            ? AnchorSpot.fromWatch(watch, name: _nameCtrl.text.trim())
            : AnchorSpot());
    return spot
      ..name = _nameCtrl.text.trim()
      ..comments = _commentsCtrl.text.trim()
      ..bottom = _bottom
      ..holdingQuality = _holding ?? ''
      ..depthMeters = depth
      ..windProtection = _windSectors.toList()
      ..swellExposure = _swell ?? ''
      ..dinghyLanding = _dinghy ?? ''
      ..dinghyNotes = _dinghyNotesCtrl.text.trim()
      ..amenities = _amenitiesCtrl.text.trim()
      ..photoPath = _photoPath;
  }

  @override
  Widget build(BuildContext context) {
    final watch = widget.watch;
    final existing = widget.existing;
    final lat = existing?.lat ?? watch?.anchorLat;
    final lon = existing?.lon ?? watch?.anchorLon;

    return AlertDialog(
      title: Text(existing == null ? 'Save this spot' : 'Edit spot'),
      content: SizedBox(
        width: 420,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (lat != null && lon != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(
                      '${lat.toStringAsFixed(5)}, ${lon.toStringAsFixed(5)}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                TextFormField(
                  controller: _nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Name',
                    hintText: 'Marsh Harbour',
                    border: OutlineInputBorder(),
                  ),
                  textCapitalization: TextCapitalization.words,
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Name is required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _commentsCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Comments',
                    hintText: 'Reef to the NE',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _bottom,
                  decoration: const InputDecoration(
                    labelText: 'Bottom / holding',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    for (final b in AnchorBottom.values)
                      DropdownMenuItem(value: b, child: Text(b)),
                  ],
                  onChanged: (v) => setState(() => _bottom = v ?? AnchorBottom.unknown),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String?>(
                  initialValue: _holding,
                  decoration: const InputDecoration(
                    labelText: 'Holding quality',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('Unknown')),
                    for (final h in AnchorHolding.values)
                      DropdownMenuItem(value: h, child: Text(h)),
                  ],
                  onChanged: (v) => setState(() => _holding = v),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _depthCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Depth at drop (m)',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                ),
                const SizedBox(height: 12),
                Text('Wind protection',
                    style: Theme.of(context).textTheme.labelLarge),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    for (final s in AnchorWindSector.values)
                      FilterChip(
                        label: Text(s),
                        selected: _windSectors.contains(s),
                        onSelected: (on) => setState(() {
                          if (on) {
                            _windSectors.add(s);
                          } else {
                            _windSectors.remove(s);
                          }
                        }),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String?>(
                  initialValue: _swell,
                  decoration: const InputDecoration(
                    labelText: 'Swell exposure',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('Unknown')),
                    for (final s in AnchorSwell.values)
                      DropdownMenuItem(value: s, child: Text(s)),
                  ],
                  onChanged: (v) => setState(() => _swell = v),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String?>(
                  initialValue: _dinghy,
                  decoration: const InputDecoration(
                    labelText: 'Shore / dinghy landing',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('Unknown')),
                    for (final d in AnchorDinghy.values)
                      DropdownMenuItem(value: d, child: Text(d)),
                  ],
                  onChanged: (v) => setState(() => _dinghy = v),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _dinghyNotesCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Landing notes',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _amenitiesCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Amenities',
                    hintText: 'Water, trash, village',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                if (_photoPath != null)
                  Stack(
                    alignment: Alignment.topRight,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(
                          File(_photoPath!),
                          height: 120,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                      IconButton(
                        onPressed: () => setState(() => _photoPath = null),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                TextButton.icon(
                  onPressed: () async {
                    final picked = await pickPhotoFromCameraOrGallery(
                      context,
                      persistPrefix: 'anchor_spot',
                    );
                    if (picked != null) {
                      setState(() => _photoPath = picked.path);
                    }
                  },
                  icon: const Icon(Icons.add_a_photo),
                  label: Text(_photoPath == null ? 'Add photo' : 'Change photo'),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            if (!_formKey.currentState!.validate()) return;
            Navigator.of(context).pop(_buildSpot());
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}

Future<AnchorSpot?> showSaveAnchorSpotDialog(
  BuildContext context, {
  AnchorWatch? watch,
  AnchorSpot? existing,
  double? depthMeters,
}) {
  return showDialog<AnchorSpot>(
    context: context,
    builder: (ctx) => SaveAnchorSpotDialog(
      watch: watch,
      existing: existing,
      depthMeters: depthMeters,
    ),
  );
}
