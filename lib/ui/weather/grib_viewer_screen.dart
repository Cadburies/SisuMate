import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../core/colors.dart';
import '../../services/grib_import_service.dart';
import '../../services/grib_parser_service.dart';

/// #244: import a GRIB2 file from device storage and view it. Fully
/// offline once imported — [GribImportService] copies the picked file into
/// app storage and remembers it, so re-opening this screen needs no
/// network call and no re-pick. Raw physical values are shown as-is
/// (GRIB's own units) — #243's parser deliberately doesn't interpret
/// parameter category/number into a specific unit, so this viewer doesn't
/// either; that mapping is a natural fast-follow, not required to satisfy
/// "see it rendered" for the wind field #243 already parses correctly.
class GribViewerScreen extends StatefulWidget {
  // Injectable for tests — GribImportService itself does real dart:io File
  // I/O even with debugDocumentsOverride set, and a widget test observing
  // that through initState's async chain needs tester.runAsync() wrapped
  // exactly right around every real I/O call or it hangs for the full test
  // timeout instead of failing fast (a real, painful lesson from writing
  // this screen's own tests). Real disk I/O is already thoroughly covered
  // by grib_import_service_test.dart directly; this injection point lets
  // the widget test instead prove the UI reacts correctly to whatever the
  // service returns, via a plain in-memory fake with no I/O at all.
  final GribImportService? importService;

  const GribViewerScreen({super.key, this.importService});

  @override
  State<GribViewerScreen> createState() => _GribViewerScreenState();
}

class _GribViewerScreenState extends State<GribViewerScreen> {
  late final GribImportService _importService =
      widget.importService ?? GribImportService();
  GribGrid? _grid;
  String? _error;
  bool _loading = false;
  bool _restoredOnce = false;

  @override
  void initState() {
    super.initState();
    _loadLastImport();
  }

  Future<void> _loadLastImport() async {
    setState(() => _loading = true);
    final grid = await _importService.loadLastImport();
    if (!mounted) return;
    setState(() {
      _grid = grid;
      _loading = false;
      _restoredOnce = true;
    });
  }

  Future<void> _importFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['grb', 'grb2', 'grib', 'grib2'],
    );
    final path = result?.files.single.path;
    if (path == null) return;

    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final bytes = await File(path).readAsBytes();
      final grid = parseGrib2(bytes);
      await _importService.persistImport(path);
      if (!mounted) return;
      setState(() {
        _grid = grid;
        _loading = false;
      });
    } on GribParseException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Could not read this GRIB file: ${e.message}';
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Could not read this file: $e';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: SisuColors.getAppBackground(isDark),
      appBar: AppBar(
        title: const Text('GRIB viewer'),
        actions: [
          IconButton(
            icon: _loading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.file_open),
            tooltip: 'Import GRIB file',
            onPressed: _loading ? null : _importFile,
          ),
        ],
      ),
      body: SafeArea(child: _buildBody(isDark)),
    );
  }

  Widget _buildBody(bool isDark) {
    if (_loading && _grid == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.error_outline,
                color: Theme.of(context).colorScheme.error),
            const SizedBox(width: 8),
            Expanded(
              child: Text(_error!,
                  style: TextStyle(
                      color: SisuColors.getTextPrimaryColor(isDark)))),
          ],
        ),
      );
    }
    final grid = _grid;
    if (grid == null) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          _restoredOnce
              ? 'No GRIB file imported yet. Tap the import icon above to '
                  'pick a .grb2 file from your device — works fully '
                  'offline once imported.'
              : '',
          style: TextStyle(color: SisuColors.getTextSecondaryColor(isDark)),
        ),
      );
    }
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        _metadataCard(grid, isDark),
        const SizedBox(height: 12),
        _valuesCard(grid, isDark),
      ],
    );
  }

  Widget _metadataCard(GribGrid grid, bool isDark) {
    return Material(
      color: SisuColors.getTileColor(isDark),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Grid',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: SisuColors.getTextPrimaryColor(isDark))),
            const SizedBox(height: 6),
            Text('${grid.ni} × ${grid.nj} points',
                style:
                    TextStyle(color: SisuColors.getTextSecondaryColor(isDark))),
            Text(
              'Lat ${grid.la1.toStringAsFixed(2)} to ${grid.la2.toStringAsFixed(2)}, '
              'Lon ${grid.lo1.toStringAsFixed(2)} to ${grid.lo2.toStringAsFixed(2)}',
              style: TextStyle(color: SisuColors.getTextSecondaryColor(isDark)),
            ),
            Text(
              'Parameter category ${grid.parameterCategory}, '
              'number ${grid.parameterNumber}',
              style: TextStyle(color: SisuColors.getTextSecondaryColor(isDark)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _valuesCard(GribGrid grid, bool isDark) {
    final min = grid.values.reduce((a, b) => a < b ? a : b);
    final max = grid.values.reduce((a, b) => a > b ? a : b);
    final mean = grid.values.reduce((a, b) => a + b) / grid.values.length;
    final total = grid.ni * grid.nj;
    // A full cell-by-cell render only makes sense for a small grid — real
    // model output (e.g. a full GFS field) can be hundreds of thousands of
    // points, which would be a ListView/Table disaster, not a viewer.
    const previewCap = 200;
    final showFullGrid = total <= previewCap;

    return Material(
      color: SisuColors.getTileColor(isDark),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Values',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: SisuColors.getTextPrimaryColor(isDark))),
            const SizedBox(height: 6),
            Text(
              'min ${min.toStringAsFixed(2)} · max ${max.toStringAsFixed(2)} '
              '· mean ${mean.toStringAsFixed(2)}',
              style: TextStyle(color: SisuColors.getTextSecondaryColor(isDark)),
            ),
            const SizedBox(height: 8),
            if (showFullGrid)
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Column(
                  children: [
                    for (var row = 0; row < grid.nj; row++)
                      Row(
                        children: [
                          for (var col = 0; col < grid.ni; col++)
                            Container(
                              width: 56,
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              alignment: Alignment.center,
                              child: Text(
                                grid.valueAt(row, col).toStringAsFixed(1),
                                style: TextStyle(
                                    fontSize: 11,
                                    color:
                                        SisuColors.getTextPrimaryColor(isDark)),
                              ),
                            ),
                        ],
                      ),
                  ],
                ),
              )
            else
              Text(
                'Grid has $total points — too many to show cell-by-cell '
                'here; showing summary stats above only.',
                style: TextStyle(color: SisuColors.getTextSecondaryColor(isDark)),
              ),
          ],
        ),
      ),
    );
  }
}
