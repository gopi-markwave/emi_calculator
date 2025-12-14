import 'dart:typed_data';
import 'package:file_saver/file_saver.dart';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:syncfusion_flutter_xlsio/xlsio.dart' hide Column, Row, Border;

class ExportUtils {
  static Future<void> exportToPDF({
    required List<Map<String, dynamic>> data,
    required String fileName,
  }) async {
    if (data.isEmpty) return;

    // --- Extract column order from first row ---
    final headers = data.first.keys.toList();

    // Create PDF Document
    final PdfDocument document = PdfDocument();
    final PdfPage page = document.pages.add();

    // Create PDF Grid (Table)
    final PdfGrid grid = PdfGrid();
    grid.columns.add(count: headers.length);

    // Header Row
    grid.headers.add(1);
    final headerRow = grid.headers[0];

    for (int i = 0; i < headers.length; i++) {
      headerRow.cells[i].value = headers[i]; // keep original names
    }

    headerRow.style = PdfGridRowStyle(
      backgroundBrush: PdfSolidBrush(PdfColor(68, 114, 196)),
      textBrush: PdfBrushes.white,
      font: PdfStandardFont(
        PdfFontFamily.helvetica,
        12,
        style: PdfFontStyle.bold,
      ),
    );

    // Data rows (Respect column order)
    for (final rowMap in data) {
      final row = grid.rows.add();
      for (int i = 0; i < headers.length; i++) {
        final key = headers[i];
        final value = rowMap[key];

        if (value is double) {
          row.cells[i].value = value.toStringAsFixed(2);
        } else {
          row.cells[i].value = value.toString();
        }
      }
    }

    // Styling
    grid.style = PdfGridStyle(
      font: PdfStandardFont(PdfFontFamily.helvetica, 10),
      cellPadding: PdfPaddings(left: 4, right: 4, top: 2, bottom: 2),
    );

    grid.applyBuiltInStyle(PdfGridBuiltInStyle.gridTable4Accent1);

    // Draw table on PDF
    grid.draw(page: page, bounds: const Rect.fromLTWH(0, 20, 0, 0));

    // Save PDF
    final List<int> bytes = document.saveSync();
    document.dispose();

    await FileSaver.instance.saveFile(
      name: "$fileName.pdf",
      bytes: Uint8List.fromList(bytes),
      mimeType: MimeType.pdf,
    );
  }

  static Future<void> exportToExcel({
    required List<Map<String, dynamic>> data,
    required String fileName,
  }) async {
    if (data.isEmpty) return;

    // Create a new Excel document
    final Workbook workbook = Workbook();
    final Worksheet sheet = workbook.worksheets[0];

    // --- Extract Headers ---
    final headers = data.first.keys.toList();

    // Write Headers
    for (int i = 0; i < headers.length; i++) {
      final cell = sheet.getRangeByIndex(1, i + 1);
      cell.setValue(headers[i]);
      cell.cellStyle.backColor = '#4472C4';
      cell.cellStyle.fontColor = '#FFFFFF';
      cell.cellStyle.bold = true;
    }

    // Write Data
    for (int i = 0; i < data.length; i++) {
      final rowMap = data[i];
      for (int j = 0; j < headers.length; j++) {
        final key = headers[j];
        final value = rowMap[key];
        final cell = sheet.getRangeByIndex(i + 2, j + 1);

        if (value is num) {
          cell.setNumber(value.toDouble());
        } else {
          cell.setValue(value.toString());
        }
      }
    }

    // Auto-fit columns
    for (int i = 0; i < headers.length; i++) {
      sheet.autoFitColumn(i + 1);
    }

    // Save
    final List<int> bytes = workbook.saveAsStream();
    workbook.dispose();

    await FileSaver.instance.saveFile(
      name: "$fileName.xlsx",
      bytes: Uint8List.fromList(bytes),
      mimeType: MimeType.microsoftExcel,
    );
  }
}
