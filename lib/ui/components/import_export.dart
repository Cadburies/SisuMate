import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/shopping_provider.dart';
import '../../services/import_service.dart';

/// Result of persisting an import batch (SUG7 — show updated vs inserted).
class ImportPersistResult {
  final int inserted;
  final int updated;

  const ImportPersistResult({this.inserted = 0, this.updated = 0});

  int get total => inserted + updated;

  /// User-facing snackbar line, e.g. `Imported 3 (2 new, 1 updated)`.
  String get snackbarMessage {
    if (total == 0) return 'Nothing to import';
    if (updated == 0) {
      return 'Imported $inserted item${inserted == 1 ? '' : 's'}';
    }
    if (inserted == 0) {
      return 'Updated $updated item${updated == 1 ? '' : 's'}';
    }
    return 'Imported $total ($inserted new, $updated updated)';
  }

  factory ImportPersistResult.fromCounts({
    required int inserted,
    required int updated,
  }) =>
      ImportPersistResult(inserted: inserted, updated: updated);

  /// Fuel logs (and other always-insert kinds) count as inserts only.
  factory ImportPersistResult.allInserted(int n) =>
      ImportPersistResult(inserted: n);
}

/// Per-module wiring for the shared JSON import/export flow (IMP1). A screen
/// supplies its `kind`, a function that serializes its current data, and a
/// function that persists a parsed batch through the module's repository.
class ModuleImportExport {
  final String kind;

  /// Human label for dialogs/snackbars, e.g. "Fuel & Water".
  final String label;

  /// Base filename for exports (without extension), e.g. "sisu_fuel".
  final String fileBaseName;

  /// Serialize the module's current data to the import JSON envelope. Async so
  /// modules with related rows (e.g. a recipe's ingredients) can gather them.
  final Future<String> Function() exportCurrent;

  /// Persist a validated batch; returns inserted vs updated counts (SUG7).
  final Future<ImportPersistResult> Function(ImportBatch batch) persist;

  /// Optional: current item display names, for the pre-import "did you mean
  /// X?" fuzzy-duplicate heads-up (BAI6). Omit to skip the check — it's
  /// informational only either way, never blocking.
  final Future<List<String>> Function()? existingNames;

  const ModuleImportExport({
    required this.kind,
    required this.label,
    required this.fileBaseName,
    required this.exportCurrent,
    required this.persist,
    this.existingNames,
  });
}

/// Opens the reusable Import/Export bottom sheet. Import is Pro-gated (it writes
/// data, matching manual add); export and the sample template are available to
/// everyone. Import is all-or-nothing: [ImportService.parse] validates the whole
/// file first, so a bad file changes nothing and the user sees the reason.
Future<void> showImportExportSheet(
  BuildContext context,
  ModuleImportExport io, {
  required bool isPro,
  required VoidCallback onProRequired,
  /// Used to stamp imported rows with the active boat (SYN3).
  WidgetRef? ref,
}) {
  return showModalBottomSheet<void>(
    context: context,
    builder: (sheetContext) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.file_upload_outlined),
            title: const Text('Import from file'),
            subtitle: const Text('Load items from a JSON file'),
            trailing: isPro ? null : const Icon(Icons.lock, size: 18),
            onTap: () {
              Navigator.of(sheetContext).pop();
              if (isPro) {
                unawaited(_runImport(context, io, ref: ref));
              } else {
                onProRequired();
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.file_download_outlined),
            title: const Text('Export to file'),
            subtitle: const Text('Save current items as JSON'),
            onTap: () async {
              final messenger = ScaffoldMessenger.of(context);
              Navigator.of(sheetContext).pop();
              _runExport(messenger, await io.exportCurrent(),
                  '${io.fileBaseName}.json', '${io.label} exported');
            },
          ),
          ListTile(
            leading: const Icon(Icons.visibility_outlined),
            title: const Text('View example format'),
            subtitle: const Text('See the expected JSON on screen'),
            onTap: () {
              Navigator.of(sheetContext).pop();
              _showExample(context, io);
            },
          ),
          ListTile(
            leading: const Icon(Icons.description_outlined),
            title: const Text('Export sample template'),
            subtitle: const Text('A blank example to fill in (or hand to an AI)'),
            onTap: () {
              final messenger = ScaffoldMessenger.of(context);
              Navigator.of(sheetContext).pop();
              _runExport(messenger, ImportService.sampleFor(io.kind),
                  '${io.fileBaseName}_template.json', 'Template exported');
            },
          ),
        ],
      ),
    ),
  );
}

Future<void> _runImport(
  BuildContext context,
  ModuleImportExport io, {
  WidgetRef? ref,
}) async {
  final messenger = ScaffoldMessenger.of(context);
  final FilePickerResult? picked;
  try {
    picked = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
      withData: true,
    );
  } catch (e) {
    messenger.showSnackBar(SnackBar(content: Text('Could not open file: $e')));
    return;
  }
  if (picked == null || picked.files.isEmpty) return; // cancelled

  final bytes = picked.files.single.bytes;
  if (bytes == null) {
    messenger.showSnackBar(
        const SnackBar(content: Text('Could not read the selected file.')));
    return;
  }

  String? boatSupabaseId;
  if (ref != null) {
    try {
      boatSupabaseId =
          (await ref.read(activeBoatProvider.future))?.supabaseId;
    } catch (_) {
      // Offline / no settings — keep placeholder boat id from parse.
    }
  }

  final ImportBatch batch;
  try {
    batch = ImportService.parse(
      utf8.decode(bytes),
      boatSupabaseId: boatSupabaseId,
    );
  } on ImportException catch (e) {
    if (context.mounted) _showError(context, e.display);
    return;
  } catch (_) {
    if (context.mounted) {
      _showError(context, 'The file could not be read as text.');
    }
    return;
  }

  if (batch.kind != io.kind) {
    if (context.mounted) {
      _showError(context,
          'This file is a "${batch.kind}" file, but this screen imports "${io.kind}".');
    }
    return;
  }

  var fuzzyWarnings = const <FuzzyDuplicateWarning>[];
  if (io.existingNames != null) {
    try {
      final existingNames = await io.existingNames!();
      fuzzyWarnings = ImportService.findFuzzyDuplicates(
        incomingNames: ImportService.namesForFuzzyCheck(batch),
        existingNames: existingNames,
      );
    } catch (_) {
      // Best-effort heads-up only — never block import on this failing.
    }
  }

  if (!context.mounted) return;
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Import'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Import ${batch.count} ${io.label} item(s)?'),
          if (fuzzyWarnings.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Text('Did you mean an existing item?',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            for (final w in fuzzyWarnings)
              Text(
                '"${w.incomingName}" looks like "${w.existingName}"',
                style: const TextStyle(fontSize: 13),
              ),
          ],
        ],
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel')),
        ElevatedButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Import')),
      ],
    ),
  );
  if (confirmed != true) return;

  try {
    final result = await io.persist(batch);
    messenger.showSnackBar(SnackBar(content: Text(result.snackbarMessage)));
  } catch (e) {
    messenger.showSnackBar(SnackBar(content: Text('Import failed: $e')));
  }
}

Future<void> _runExport(ScaffoldMessengerState messenger, String json,
    String fileName, String successMessage) async {
  try {
    final path = await FilePicker.platform.saveFile(
      dialogTitle: 'Save $fileName',
      fileName: fileName,
      type: FileType.custom,
      allowedExtensions: ['json'],
      bytes: Uint8List.fromList(utf8.encode(json)),
    );
    if (path == null) return; // cancelled
    messenger.showSnackBar(SnackBar(content: Text(successMessage)));
  } catch (e) {
    messenger.showSnackBar(SnackBar(content: Text('Export failed: $e')));
  }
}

void _showExample(BuildContext context, ModuleImportExport io) {
  showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text('${io.label} — example'),
      content: SizedBox(
        width: 400,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SingleChildScrollView(
            child: SelectableText(
              ImportService.sampleFor(io.kind),
              style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Close')),
      ],
    ),
  );
}

void _showError(BuildContext context, String message) {
  showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text("Couldn't import"),
      content: Text(message),
      actions: [
        TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('OK')),
      ],
    ),
  );
}
