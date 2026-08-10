import 'dart:io';
import 'dart:typed_data';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/models.dart';

/// Exports a selected subset of records (Documents, Crew, Inventory) as a PDF
/// and hands it to the OS share sheet (email, WhatsApp, Save to Downloads, …).
///
/// The build* methods are pure and return the PDF bytes so they can be unit
/// tested; the share* methods wrap them with `Printing.sharePdf`, which is the
/// same platform share path used by [RecipeShareService]. A `-` prefix is used
/// for list items rather than `•` because the pdf package's core font has no
/// glyph for U+2022 (see CF12/BC11).
class RecordShareService {
  static Future<void> shareDocuments(List<Document> documents) async {
    await Printing.sharePdf(
      bytes: await buildDocumentsPdf(documents),
      filename: 'boat_documents.pdf',
    );
  }

  static Future<void> shareCrew(List<CrewMember> members) async {
    await Printing.sharePdf(
      bytes: await buildCrewPdf(members),
      filename: 'crew_list.pdf',
    );
  }

  static Future<void> shareInventory(List<InventoryItem> items) async {
    await Printing.sharePdf(
      bytes: await buildInventoryPdf(items),
      filename: 'inventory.pdf',
    );
  }

  static pw.Widget _sectionTitle(String text) => pw.Text(
        text,
        style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold),
      );

  static pw.MemoryImage? _tryLoadImage(String? path) {
    if (path == null) return null;
    final file = File(path);
    if (!file.existsSync()) return null;
    try {
      return pw.MemoryImage(file.readAsBytesSync());
    } catch (_) {
      return null;
    }
  }

  static String _formatDate(DateTime d) => d.toString().split(' ')[0];

  static Future<Uint8List> buildDocumentsPdf(List<Document> documents) async {
    final doc = pw.Document();
    doc.addPage(
      pw.MultiPage(
        margin: const pw.EdgeInsets.all(32),
        build: (context) => [
          _sectionTitle('Boat Documents'),
          pw.SizedBox(height: 16),
          ...documents.map((d) {
            final image = _tryLoadImage(d.localPath);
            return pw.Container(
              margin: const pw.EdgeInsets.only(bottom: 20),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(d.title,
                      style: pw.TextStyle(
                          fontSize: 15, fontWeight: pw.FontWeight.bold)),
                  pw.SizedBox(height: 4),
                  pw.Text('Type: ${d.type}',
                      style: const pw.TextStyle(fontSize: 11)),
                  if (d.expiry != null)
                    pw.Text('Expires: ${_formatDate(d.expiry!)}',
                        style: const pw.TextStyle(fontSize: 11)),
                  if (d.notes != null && d.notes!.isNotEmpty)
                    pw.Text(d.notes!, style: const pw.TextStyle(fontSize: 11)),
                  if (image != null) ...[
                    pw.SizedBox(height: 8),
                    pw.Image(image, height: 260, fit: pw.BoxFit.contain,
                        alignment: pw.Alignment.centerLeft),
                  ],
                  pw.SizedBox(height: 8),
                  pw.Divider(thickness: 0.5),
                ],
              ),
            );
          }),
        ],
      ),
    );
    return doc.save();
  }

  static Future<Uint8List> buildCrewPdf(List<CrewMember> members) async {
    final doc = pw.Document();
    doc.addPage(
      pw.MultiPage(
        margin: const pw.EdgeInsets.all(32),
        build: (context) => [
          _sectionTitle('Crew List'),
          pw.SizedBox(height: 16),
          ...members.map((m) {
            // #326 — DOB/nationality/passport # first: the fields a port
            // authority's crew list actually asks for, ahead of contact
            // details.
            final lines = <String>['Role: ${m.role}'];
            if (m.dateOfBirth != null) {
              lines.add('Date of birth: ${_formatDate(m.dateOfBirth!)}');
            }
            if (m.nationality != null && m.nationality!.isNotEmpty) {
              lines.add('Nationality: ${m.nationality}');
            }
            if (m.passportNumber != null && m.passportNumber!.isNotEmpty) {
              lines.add('Passport #: ${m.passportNumber}');
            }
            if (m.phone != null && m.phone!.isNotEmpty) {
              lines.add('Phone: ${m.phone}');
            }
            if (m.email != null && m.email!.isNotEmpty) {
              lines.add('Email: ${m.email}');
            }
            if (m.iceContact != null && m.iceContact!.isNotEmpty) {
              lines.add('ICE: ${m.iceContact}');
            }
            if (m.certifications != null && m.certifications!.isNotEmpty) {
              lines.add('Certifications: ${m.certifications}');
            }
            return pw.Container(
              margin: const pw.EdgeInsets.only(bottom: 14),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(m.name,
                      style: pw.TextStyle(
                          fontSize: 14, fontWeight: pw.FontWeight.bold)),
                  ...lines.map((l) =>
                      pw.Text(l, style: const pw.TextStyle(fontSize: 11))),
                  pw.SizedBox(height: 6),
                  pw.Divider(thickness: 0.5),
                ],
              ),
            );
          }),
        ],
      ),
    );
    return doc.save();
  }

  static Future<Uint8List> buildInventoryPdf(List<InventoryItem> items) async {
    final doc = pw.Document();
    doc.addPage(
      pw.MultiPage(
        margin: const pw.EdgeInsets.all(32),
        build: (context) => [
          _sectionTitle('Inventory'),
          pw.SizedBox(height: 16),
          ...items.map((i) {
            final qty = i.quantity == i.quantity.roundToDouble()
                ? i.quantity.toInt().toString()
                : i.quantity.toString();
            final unit =
                i.unit != null && i.unit!.isNotEmpty ? ' ${i.unit}' : '';
            final lines = <String>['Quantity: $qty$unit'];
            if (i.location != null && i.location!.isNotEmpty) {
              lines.add('Location: ${i.location}');
            }
            if (i.serialNumber != null && i.serialNumber!.isNotEmpty) {
              lines.add('Serial: ${i.serialNumber}');
            }
            if (i.notes != null && i.notes!.isNotEmpty) {
              lines.add(i.notes!);
            }
            return pw.Container(
              margin: const pw.EdgeInsets.only(bottom: 14),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(i.name,
                      style: pw.TextStyle(
                          fontSize: 14, fontWeight: pw.FontWeight.bold)),
                  ...lines.map((l) =>
                      pw.Text(l, style: const pw.TextStyle(fontSize: 11))),
                  pw.SizedBox(height: 6),
                  pw.Divider(thickness: 0.5),
                ],
              ),
            );
          }),
        ],
      ),
    );
    return doc.save();
  }
}
