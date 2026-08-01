import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/models.dart';

/// Print/share a styled recipe card as a PDF. Shared by Chef (CF12) and
/// Cocktails (BC11) recipe detail screens.
///
/// [buildRecipeCardPdf] is pure (returns bytes) so it can be unit tested;
/// [shareRecipeCard] wraps it with `Printing.layoutPdf` (platform share sheet).
class RecipeShareService {
  static Future<void> shareRecipeCard({
    required Recipe recipe,
    required List<RecipeIngredient> ingredients,
  }) async {
    await Printing.layoutPdf(
      name: recipe.name,
      onLayout: (format) => buildRecipeCardPdf(recipe, ingredients, format),
    );
  }

  /// Builds a recipe-card PDF without touching the platform share sheet (TEST3).
  static Future<Uint8List> buildRecipeCardPdf(
    Recipe recipe,
    List<RecipeIngredient> ingredients, [
    PdfPageFormat format = PdfPageFormat.a4,
  ]) async {
    final doc = pw.Document();

    doc.addPage(
      pw.Page(
        pageFormat: format,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(recipe.name,
                style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
            if (recipe.cuisine.isNotEmpty) ...[
              pw.SizedBox(height: 4),
              pw.Text(recipe.cuisine.join(' · '),
                  style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey700)),
            ],
            if (recipe.description != null) ...[
              pw.SizedBox(height: 10),
              pw.Text(recipe.description!, style: const pw.TextStyle(fontSize: 11)),
            ],
            if (recipe.prepMinutes != null || recipe.cookMinutes != null) ...[
              pw.SizedBox(height: 10),
              pw.Row(children: [
                if (recipe.prepMinutes != null)
                  pw.Text('Prep: ${recipe.prepMinutes} min',
                      style: const pw.TextStyle(fontSize: 11)),
                if (recipe.prepMinutes != null && recipe.cookMinutes != null)
                  pw.SizedBox(width: 16),
                if (recipe.cookMinutes != null)
                  pw.Text('Cook: ${recipe.cookMinutes} min',
                      style: const pw.TextStyle(fontSize: 11)),
              ]),
            ],
            if (recipe.glassware != null) ...[
              pw.SizedBox(height: 4),
              pw.Text('Glassware: ${recipe.glassware}',
                  style: const pw.TextStyle(fontSize: 11)),
            ],
            pw.SizedBox(height: 18),
            pw.Text('Ingredients',
                style: pw.TextStyle(fontSize: 15, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 6),
            pw.Divider(thickness: 0.5),
            ...ingredients.map((i) => pw.Padding(
                  padding: const pw.EdgeInsets.only(bottom: 4),
                  child: pw.Text('-  ${formatIngredient(i)}',
                      style: const pw.TextStyle(fontSize: 11)),
                )),
            if (recipe.instructions != null) ...[
              pw.SizedBox(height: 18),
              pw.Text('Instructions',
                  style: pw.TextStyle(fontSize: 15, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 6),
              pw.Divider(thickness: 0.5),
              pw.Text(recipe.instructions!, style: const pw.TextStyle(fontSize: 11)),
            ],
          ],
        ),
      ),
    );

    return doc.save();
  }

  /// Formats one ingredient line for the PDF card (public for unit tests).
  static String formatIngredient(RecipeIngredient i) {
    final parts = <String>[];
    if (i.quantity != null) {
      parts.add(i.quantity! == i.quantity!.roundToDouble()
          ? i.quantity!.toInt().toString()
          : i.quantity!.toString());
    }
    if (i.unit != null) parts.add(i.unit!);
    parts.add(i.name);
    if (i.isOptional) parts.add('(optional)');
    if (i.isGarnish) parts.add('(garnish)');
    return parts.join(' ');
  }
}
