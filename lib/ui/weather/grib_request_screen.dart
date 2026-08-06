import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/app_router.dart';
import '../../core/colors.dart';
import '../../services/grib_download_service.dart';
import '../../services/saildocs_query_service.dart';

/// #245/#281: free GRIB for a planned area — direct NOAA GFS download and/or
/// Saildocs email query (low-bandwidth). Response files open in the GRIB viewer.
class GribRequestScreen extends StatefulWidget {
  final double? initialLat;
  final double? initialLon;
  final double? initialLatMin;
  final double? initialLatMax;
  final double? initialLonMin;
  final double? initialLonMax;

  const GribRequestScreen({
    super.key,
    this.initialLat,
    this.initialLon,
    this.initialLatMin,
    this.initialLatMax,
    this.initialLonMin,
    this.initialLonMax,
  });

  @override
  State<GribRequestScreen> createState() => _GribRequestScreenState();
}

class _GribRequestScreenState extends State<GribRequestScreen> {
  static const _defaultLat = 12.05; // southern Grenada-ish seed (not a city)
  static const _defaultLon = -61.75;
  static const _defaultBoxDeg = 2.0;

  late final TextEditingController _latMinCtrl;
  late final TextEditingController _latMaxCtrl;
  late final TextEditingController _lonMinCtrl;
  late final TextEditingController _lonMaxCtrl;
  final _latResCtrl = TextEditingController(text: '1');
  final _lonResCtrl = TextEditingController(text: '1');
  final _hoursCtrl = TextEditingController(text: '0,24,48,72');
  final Set<String> _selectedParams = {'WIND'};
  bool _downloading = false;
  String? _downloadStatus;

  @override
  void initState() {
    super.initState();
    if (widget.initialLatMin != null &&
        widget.initialLatMax != null &&
        widget.initialLonMin != null &&
        widget.initialLonMax != null) {
      _latMinCtrl = TextEditingController(
          text: widget.initialLatMin!.toStringAsFixed(2));
      _latMaxCtrl = TextEditingController(
          text: widget.initialLatMax!.toStringAsFixed(2));
      _lonMinCtrl = TextEditingController(
          text: widget.initialLonMin!.toStringAsFixed(2));
      _lonMaxCtrl = TextEditingController(
          text: widget.initialLonMax!.toStringAsFixed(2));
    } else {
      final lat = widget.initialLat ?? _defaultLat;
      final lon = widget.initialLon ?? _defaultLon;
      _latMinCtrl =
          TextEditingController(text: (lat - _defaultBoxDeg).toStringAsFixed(1));
      _latMaxCtrl =
          TextEditingController(text: (lat + _defaultBoxDeg).toStringAsFixed(1));
      _lonMinCtrl =
          TextEditingController(text: (lon - _defaultBoxDeg).toStringAsFixed(1));
      _lonMaxCtrl =
          TextEditingController(text: (lon + _defaultBoxDeg).toStringAsFixed(1));
    }
  }

  @override
  void dispose() {
    _latMinCtrl.dispose();
    _latMaxCtrl.dispose();
    _lonMinCtrl.dispose();
    _lonMaxCtrl.dispose();
    _latResCtrl.dispose();
    _lonResCtrl.dispose();
    _hoursCtrl.dispose();
    super.dispose();
  }

  GribBBox? _bbox() {
    final latMin = double.tryParse(_latMinCtrl.text.trim());
    final latMax = double.tryParse(_latMaxCtrl.text.trim());
    final lonMin = double.tryParse(_lonMinCtrl.text.trim());
    final lonMax = double.tryParse(_lonMaxCtrl.text.trim());
    if (latMin == null ||
        latMax == null ||
        lonMin == null ||
        lonMax == null) {
      return null;
    }
    return GribBBox(
      latMin: latMin,
      latMax: latMax,
      lonMin: lonMin,
      lonMax: lonMax,
    );
  }

  SaildocsQueryParams? _params() {
    final box = _bbox();
    final latRes = double.tryParse(_latResCtrl.text.trim());
    final lonRes = double.tryParse(_lonResCtrl.text.trim());
    if (box == null || latRes == null || lonRes == null) return null;
    final hours = _hoursCtrl.text
        .split(',')
        .map((s) => int.tryParse(s.trim()))
        .whereType<int>()
        .toList();
    // Saildocs uses positive forecast hours; drop analysis (0) if present.
    final saildocsHours = hours.where((h) => h > 0).toList();
    if (saildocsHours.isEmpty || _selectedParams.isEmpty) return null;
    final b = box.normalized();
    return SaildocsQueryParams(
      latMin: b.latMin,
      latMax: b.latMax,
      lonMin: b.lonMin,
      lonMax: b.lonMax,
      latResolution: latRes,
      lonResolution: lonRes,
      forecastHours: saildocsHours,
      parameters: _selectedParams.toList(),
    );
  }

  List<int> _hours() => _hoursCtrl.text
      .split(',')
      .map((s) => int.tryParse(s.trim()))
      .whereType<int>()
      .toList();

  Future<void> _copyQuery(String query) async {
    await Clipboard.setData(ClipboardData(text: query));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Query copied to clipboard')),
    );
  }

  Future<void> _openInEmailApp(String query) async {
    final uri = buildSaildocsMailtoUri(query);
    final launched = await launchUrl(uri);
    if (!mounted || launched) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text(
          'Could not open an email app — use Copy and paste into your '
          'satellite/HF email client instead.'),
    ));
  }

  Future<void> _downloadFreeNoaa() async {
    final box = _bbox();
    final hours = _hours();
    if (box == null || hours.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Enter a valid area and forecast hours first.'),
      ));
      return;
    }
    setState(() {
      _downloading = true;
      _downloadStatus = 'Starting free NOAA GFS download…';
    });
    final svc = GribDownloadService();
    try {
      final result = await svc.downloadNoaaGfs(
        box: box,
        forecastHours: hours,
        onProgress: (s) {
          if (mounted) setState(() => _downloadStatus = s);
        },
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.message)),
      );
      if (result.ok) {
        context.push(AppRoutes.gribViewer);
      }
    } finally {
      svc.close();
      if (mounted) {
        setState(() {
          _downloading = false;
          _downloadStatus = null;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final params = _params();
    final query = params == null ? null : buildSaildocsQuery(params);
    final primary = SisuColors.getTextPrimaryColor(isDark);
    final secondary = SisuColors.getTextSecondaryColor(isDark);

    return Scaffold(
      backgroundColor: SisuColors.getAppBackground(isDark),
      appBar: AppBar(title: const Text('Free GRIB download')),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          Text(
            'Download free forecast GRIBs for the area you are planning, '
            'or build a Saildocs email request for low-bandwidth (sat/HF). '
            'Imported files open in the GRIB viewer.',
            style: TextStyle(color: secondary, height: 1.35),
          ),
          const SizedBox(height: 16),
          Text('Area (degrees)',
              style: TextStyle(fontWeight: FontWeight.bold, color: primary)),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                  child: _numberField(_latMinCtrl, 'Lat min (S)', signed: true)),
              const SizedBox(width: 8),
              Expanded(
                  child: _numberField(_latMaxCtrl, 'Lat max (N)', signed: true)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                  child: _numberField(_lonMinCtrl, 'Lon min (W)', signed: true)),
              const SizedBox(width: 8),
              Expanded(
                  child: _numberField(_lonMaxCtrl, 'Lon max (E)', signed: true)),
            ],
          ),
          const SizedBox(height: 12),
          Text('Forecast hours (comma-separated)',
              style: TextStyle(fontWeight: FontWeight.bold, color: primary)),
          const SizedBox(height: 6),
          TextField(
            controller: _hoursCtrl,
            decoration: const InputDecoration(
                isDense: true, border: OutlineInputBorder()),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 16),
          // ── Free direct download (NOAA) ────────────────────────────
          DecoratedBox(
            decoration: BoxDecoration(
              color: SisuColors.getTileColor(isDark),
              borderRadius: BorderRadius.circular(12),
              boxShadow: SisuColors.tileElevation(isDark),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Free direct download — NOAA GFS 0.25°',
                      style: TextStyle(
                          fontWeight: FontWeight.w700, color: primary)),
                  const SizedBox(height: 6),
                  Text(
                    'No account. Wind (10 m U/V) + mean sea level pressure '
                    'for your box from NOMADS. Needs normal internet '
                    '(not sat email). Multiple hours are saved as one GRIB.',
                    style: TextStyle(color: secondary, fontSize: 12, height: 1.3),
                  ),
                  const SizedBox(height: 10),
                  if (_downloadStatus != null) ...[
                    Text(_downloadStatus!,
                        style: TextStyle(color: secondary, fontSize: 12)),
                    const SizedBox(height: 8),
                  ],
                  FilledButton.icon(
                    onPressed: _downloading ? null : _downloadFreeNoaa,
                    icon: _downloading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.cloud_download_outlined, size: 18),
                    label: Text(
                      _downloading
                          ? 'Downloading…'
                          : 'Download free GFS for this area',
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // ── Saildocs (low bandwidth) ───────────────────────────────
          Text('Low-bandwidth — Saildocs email (also free)',
              style: TextStyle(fontWeight: FontWeight.bold, color: primary)),
          const SizedBox(height: 6),
          Text(
            'Builds a query for query@saildocs.com. This app never sends '
            'the email — hand it off to your satellite/HF client. Import '
            'the GRIB attachment in the viewer when it arrives.',
            style: TextStyle(color: secondary, fontSize: 12, height: 1.3),
          ),
          const SizedBox(height: 12),
          Text('Resolution (degrees, Saildocs only)',
              style: TextStyle(fontWeight: FontWeight.w600, color: primary)),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(child: _numberField(_latResCtrl, 'Lat step')),
              const SizedBox(width: 8),
              Expanded(child: _numberField(_lonResCtrl, 'Lon step')),
            ],
          ),
          const SizedBox(height: 12),
          Text('Parameters (Saildocs)',
              style: TextStyle(fontWeight: FontWeight.w600, color: primary)),
          Wrap(
            spacing: 8,
            children: [
              for (final p in const ['WIND', 'WAVES', 'PRMSL'])
                FilterChip(
                  label: Text(p),
                  selected: _selectedParams.contains(p),
                  onSelected: (sel) => setState(() {
                    if (sel) {
                      _selectedParams.add(p);
                    } else {
                      _selectedParams.remove(p);
                    }
                  }),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text('Query',
              style: TextStyle(fontWeight: FontWeight.w600, color: primary)),
          const SizedBox(height: 6),
          if (query == null)
            Text('Enter valid area/resolution/hours/parameters above.',
                style: TextStyle(color: secondary))
          else ...[
            SelectableText(query,
                style: TextStyle(fontFamily: 'monospace', color: primary)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: [
                ElevatedButton.icon(
                  onPressed: () => _copyQuery(query),
                  icon: const Icon(Icons.copy),
                  label: const Text('Copy'),
                ),
                ElevatedButton.icon(
                  onPressed: () => _openInEmailApp(query),
                  icon: const Icon(Icons.email_outlined),
                  label: const Text('Open in email app'),
                ),
              ],
            ),
          ],
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: () => context.push(AppRoutes.gribViewer),
            icon: const Icon(Icons.map_outlined, size: 18),
            label: const Text('Open GRIB viewer'),
          ),
        ],
      ),
    );
  }

  Widget _numberField(TextEditingController ctrl, String label,
      {bool signed = false}) {
    return TextField(
      controller: ctrl,
      decoration: InputDecoration(
          labelText: label, isDense: true, border: const OutlineInputBorder()),
      keyboardType:
          TextInputType.numberWithOptions(decimal: true, signed: signed),
      onChanged: (_) => setState(() {}),
    );
  }
}
