import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/colors.dart';
import '../../services/saildocs_query_service.dart';

/// #245: low-bandwidth GRIB request — builds a saildocs-style query for a
/// bounding box and hands it off via `mailto:` (or clipboard, as a
/// fallback for setups where `mailto:` isn't wired to anything useful,
/// e.g. a satellite messenger app that isn't the OS default mail handler)
/// to whichever email client the user already has configured for their
/// satellite/HF connection. This app never sends the email itself. The
/// response (a GRIB attachment) is imported via #244's existing GRIB
/// viewer — no new receiving mechanism here.
class GribRequestScreen extends StatefulWidget {
  final double? initialLat;
  final double? initialLon;

  const GribRequestScreen({super.key, this.initialLat, this.initialLon});

  @override
  State<GribRequestScreen> createState() => _GribRequestScreenState();
}

class _GribRequestScreenState extends State<GribRequestScreen> {
  static const _defaultLat = 33.45;
  static const _defaultLon = -112.07;
  static const _defaultBoxDeg = 2.0;

  late final TextEditingController _latMinCtrl;
  late final TextEditingController _latMaxCtrl;
  late final TextEditingController _lonMinCtrl;
  late final TextEditingController _lonMaxCtrl;
  final _latResCtrl = TextEditingController(text: '1');
  final _lonResCtrl = TextEditingController(text: '1');
  final _hoursCtrl = TextEditingController(text: '24,48,72');
  final Set<String> _selectedParams = {'WIND'};

  @override
  void initState() {
    super.initState();
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

  SaildocsQueryParams? _params() {
    final latMin = double.tryParse(_latMinCtrl.text.trim());
    final latMax = double.tryParse(_latMaxCtrl.text.trim());
    final lonMin = double.tryParse(_lonMinCtrl.text.trim());
    final lonMax = double.tryParse(_lonMaxCtrl.text.trim());
    final latRes = double.tryParse(_latResCtrl.text.trim());
    final lonRes = double.tryParse(_lonResCtrl.text.trim());
    if (latMin == null ||
        latMax == null ||
        lonMin == null ||
        lonMax == null ||
        latRes == null ||
        lonRes == null) {
      return null;
    }
    final hours = _hoursCtrl.text
        .split(',')
        .map((s) => int.tryParse(s.trim()))
        .whereType<int>()
        .toList();
    if (hours.isEmpty || _selectedParams.isEmpty) return null;
    return SaildocsQueryParams(
      latMin: latMin,
      latMax: latMax,
      lonMin: lonMin,
      lonMax: lonMax,
      latResolution: latRes,
      lonResolution: lonRes,
      forecastHours: hours,
      parameters: _selectedParams.toList(),
    );
  }

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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final params = _params();
    final query = params == null ? null : buildSaildocsQuery(params);

    return Scaffold(
      backgroundColor: SisuColors.getAppBackground(isDark),
      appBar: AppBar(title: const Text('Request GRIB (low-bandwidth)')),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          Text(
            'Builds a saildocs-style GRIB request for a low-bandwidth '
            'connection (satellite/HF email). This never sends the '
            'email itself — hand it off to whichever email client you '
            'already use offshore. Import the GRIB file you receive back '
            'via the GRIB viewer.',
            style: TextStyle(color: SisuColors.getTextSecondaryColor(isDark)),
          ),
          const SizedBox(height: 12),
          Text('Area',
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: SisuColors.getTextPrimaryColor(isDark))),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                  child: _numberField(_latMinCtrl, 'Lat min', signed: true)),
              const SizedBox(width: 8),
              Expanded(
                  child: _numberField(_latMaxCtrl, 'Lat max', signed: true)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                  child: _numberField(_lonMinCtrl, 'Lon min', signed: true)),
              const SizedBox(width: 8),
              Expanded(
                  child: _numberField(_lonMaxCtrl, 'Lon max', signed: true)),
            ],
          ),
          const SizedBox(height: 12),
          Text('Resolution (degrees)',
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: SisuColors.getTextPrimaryColor(isDark))),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(child: _numberField(_latResCtrl, 'Lat step')),
              const SizedBox(width: 8),
              Expanded(child: _numberField(_lonResCtrl, 'Lon step')),
            ],
          ),
          const SizedBox(height: 12),
          Text('Forecast hours (comma-separated)',
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: SisuColors.getTextPrimaryColor(isDark))),
          const SizedBox(height: 6),
          TextField(
            controller: _hoursCtrl,
            decoration: const InputDecoration(
                isDense: true, border: OutlineInputBorder()),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),
          Text('Parameters',
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: SisuColors.getTextPrimaryColor(isDark))),
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
          const SizedBox(height: 16),
          Text('Query',
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: SisuColors.getTextPrimaryColor(isDark))),
          const SizedBox(height: 6),
          if (query == null)
            Text('Enter valid area/resolution/hours/parameters above.',
                style: TextStyle(color: SisuColors.getTextSecondaryColor(isDark)))
          else ...[
            SelectableText(query,
                style: TextStyle(
                    fontFamily: 'monospace',
                    color: SisuColors.getTextPrimaryColor(isDark))),
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
        ],
      ),
    );
  }

  Widget _numberField(TextEditingController ctrl, String label,
      {bool signed = false}) {
    return TextField(
      controller: ctrl,
      decoration:
          InputDecoration(labelText: label, isDense: true, border: const OutlineInputBorder()),
      keyboardType: TextInputType.numberWithOptions(decimal: true, signed: signed),
      onChanged: (_) => setState(() {}),
    );
  }
}
