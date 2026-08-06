import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'error_log_service.dart';
import 'grib_parser_service.dart';

/// #244: persists an imported GRIB file into app storage (mirrors
/// [ImageService]'s pattern — a file-picker temp path may be purged by the
/// OS, so always copy through app storage before remembering it) and
/// remembers the last import so the viewer works fully offline afterward,
/// with no network call needed.
class GribImportService {
  static const _lastImportPathKey = 'grib_last_import_path';
  static const _dirName = 'grib_files';

  /// Override for unit tests (skips [getApplicationDocumentsDirectory]).
  Directory? debugDocumentsOverride;

  Future<Directory> _documentsDir() async {
    if (debugDocumentsOverride != null) return debugDocumentsOverride!;
    return getApplicationDocumentsDirectory();
  }

  Future<String> _nextPath(String ext, {String prefix = 'import'}) async {
    final docs = await _documentsDir();
    final dirPath = '${docs.path}/$_dirName';
    await Directory(dirPath).create(recursive: true);
    return '$dirPath/${prefix}_${DateTime.now().millisecondsSinceEpoch}$ext';
  }

  /// Copies [sourcePath]'s bytes into durable app storage and remembers it
  /// as the last import. Only call this after the file has already been
  /// confirmed to parse successfully — a corrupt file must never be
  /// persisted as "the last import" (the viewer would otherwise silently
  /// keep re-surfacing the same failure on every future open).
  Future<String> persistImport(String sourcePath) async {
    final dot = sourcePath.lastIndexOf('.');
    final ext = dot > 0 ? sourcePath.substring(dot) : '.grb2';
    final destPath = await _nextPath(ext);
    await File(sourcePath).copy(destPath);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastImportPathKey, destPath);
    return destPath;
  }

  /// #281 — persist raw GRIB bytes (e.g. free NOAA NOMADS download) and
  /// remember as last import for the viewer.
  Future<String> persistBytes(
    Uint8List bytes, {
    String suggestedName = 'download',
    String ext = '.grb2',
  }) async {
    final safe = suggestedName.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
    final destPath = await _nextPath(ext, prefix: safe);
    await File(destPath).writeAsBytes(bytes, flush: true);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastImportPathKey, destPath);
    return destPath;
  }

  Future<String?> lastImportPath() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_lastImportPathKey);
  }

  /// Loads + parses the last imported file, if any. Returns null when
  /// there's no prior import, or the previously-imported file has since
  /// gone missing/corrupt on disk — the viewer shows "no file imported
  /// yet" either way. Never throws.
  Future<GribGrid?> loadLastImport() async {
    final path = await lastImportPath();
    if (path == null) return null;
    final file = File(path);
    try {
      if (!await file.exists()) return null;
      return parseGrib2(await file.readAsBytes());
    } catch (e) {
      unawaited(ErrorLogService().logWarning(
        'previously-imported GRIB file failed to reload: $e',
        context: 'grib_import_service: loadLastImport',
      ));
      return null;
    }
  }
}
