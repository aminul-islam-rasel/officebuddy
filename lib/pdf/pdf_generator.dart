import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import '../models/work_entry.dart';

class PDFGenerator {
  static String _formatHours(double hours) {
    int totalMinutes = (hours * 60).round();
    int h = totalMinutes ~/ 60;
    int m = totalMinutes % 60;
    if (h == 0) return '${m}m';
    if (m == 0) return '${h}h';
    return '${h}h ${m}m';
  }

  static Future<pw.Document> generateRangePDF({
    required List<WorkEntry> entries,
    required String title,
    required String subtitle,
  }) async {
    final pdf = pw.Document();
    final sortedEntries = List<WorkEntry>.from(entries);

    // Load logo
    pw.MemoryImage? logo;
    try {
      final logoData = await rootBundle.load('assets/images/company logo.jpg');
      logo = pw.MemoryImage(logoData.buffer.asUint8List());
    } catch (e) {
      debugPrint('Error loading logo: $e');
    }

    if (sortedEntries.isEmpty) {
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          build: (pw.Context context) {
            return pw.Center(
              child: pw.Text(
                'No work entries found for $subtitle',
                style: pw.TextStyle(fontSize: 18, color: PdfColors.grey600),
              ),
            );
          },
        ),
      );
      return pdf;
    }

    double totalWorkedHours = 0;
    final projectBreakdown = <String, double>{};

    for (final entry in sortedEntries) {
      final hours = entry.workedHours;
      totalWorkedHours += hours;
      final projectName = entry.projectName;
      projectBreakdown[projectName] = (projectBreakdown[projectName] ?? 0) + hours;
    }

    sortedEntries.sort((a, b) => b.date.compareTo(a.date));

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        footer: (pw.Context context) {
          return pw.Container(
            alignment: pw.Alignment.centerRight,
            margin: const pw.EdgeInsets.only(top: 16),
            child: pw.Text(
              'Page ${context.pageNumber}',
              style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
            ),
          );
        },
        build: (pw.Context context) => [
          pw.Container(
            padding: const pw.EdgeInsets.only(bottom: 16),
            decoration: const pw.BoxDecoration(
              border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey300, width: 1)),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('Office Buddy', 
                      style: pw.TextStyle(fontSize: 28, fontWeight: pw.FontWeight.bold, color: PdfColor.fromHex('#1976D2'))),
                    pw.Text(title, style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
                    pw.SizedBox(height: 8),
                    pw.Text(subtitle, style: const pw.TextStyle(fontSize: 16, color: PdfColors.grey700)),
                    pw.Text('Generated on ${DateFormat('MMM dd, yyyy').format(DateTime.now())}', 
                      style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey600)),
                  ],
                ),
                if (logo != null)
                  pw.Container(
                    height: 60,
                    width: 60,
                    child: pw.Image(logo),
                  ),
              ],
            ),
          ),
          pw.SizedBox(height: 24),
          pw.Container(
            padding: const pw.EdgeInsets.all(16),
            decoration: pw.BoxDecoration(
              color: PdfColors.blue50,
              borderRadius: pw.BorderRadius.circular(8),
              border: pw.Border.all(color: PdfColors.blue200),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                _buildSummaryItem('Total Hours', _formatHours(totalWorkedHours)),
                _buildSummaryItem('Entries', '${sortedEntries.length}'),
                _buildSummaryItem('Projects', '${projectBreakdown.length}'),
              ],
            ),
          ),
          pw.SizedBox(height: 24),

          pw.Text('Project Summary (Time Breakdown)', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 10),
          pw.Column(
            children: projectBreakdown.entries.map((entry) {
              return pw.Container(
                padding: const pw.EdgeInsets.symmetric(vertical: 4),
                decoration: const pw.BoxDecoration(
                  border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey200, width: 0.5)),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(entry.key, style: const pw.TextStyle(fontSize: 12)),
                    pw.Text(_formatHours(entry.value), style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
                  ],
                ),
              );
            }).toList(),
          ),
          pw.SizedBox(height: 24),

          pw.Text('Detailed Work Entries', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 8),
          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
            columnWidths: {
              0: const pw.FlexColumnWidth(2),
              1: const pw.FlexColumnWidth(2),
              2: const pw.FlexColumnWidth(1),
              3: const pw.FlexColumnWidth(3),
            },
            children: [
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                children: [
                  _buildTableHeader('Date'),
                  _buildTableHeader('Project'),
                  _buildTableHeader('Hours'),
                  _buildTableHeader('Details'),
                ],
              ),
              ...sortedEntries.map((entry) {
                return pw.TableRow(
                  children: [
                    _buildTableCell(DateFormat('MMM dd, yyyy').format(entry.date)),
                    _buildTableCell(entry.projectName),
                    _buildTableCell(_formatHours(entry.workedHours)),
                    _buildTableCell(entry.details.isEmpty ? '-' : entry.details, maxLines: 3),
                  ],
                );
              }),
            ],
          ),
        ],
      ),
    );
    return pdf;
  }

  static Future<pw.Document> generateMonthlyPDF({
    required List<WorkEntry> entries,
    required int year,
    required int month,
  }) async {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return generateRangePDF(
      entries: entries,
      title: 'Monthly Work Report',
      subtitle: '${months[month - 1]} $year',
    );
  }

  static Future<pw.Document> _generateProjectPDF({required List<WorkEntry> entries, required String projectName}) async {
    final pdf = pw.Document();
    final sortedEntries = List<WorkEntry>.from(entries);

    pw.MemoryImage? logo;
    try {
      final logoData = await rootBundle.load('assets/images/company logo.jpg');
      logo = pw.MemoryImage(logoData.buffer.asUint8List());
    } catch (e) {
      debugPrint('Error loading logo: $e');
    }

    if (sortedEntries.isEmpty) {
      pdf.addPage(pw.Page(build: (context) => pw.Center(child: pw.Text('No data for $projectName'))));
      return pdf;
    }

    double totalHours = 0;
    for (var e in sortedEntries) {
      totalHours += e.workedHours;
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => [
          pw.Container(
            padding: const pw.EdgeInsets.only(bottom: 16),
            decoration: const pw.BoxDecoration(
              border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey300, width: 1)),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('Office Buddy', 
                      style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold, color: PdfColor.fromHex('#1976D2'))),
                    pw.Text('Project Report: $projectName', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
                    pw.SizedBox(height: 8),
                    pw.Text('Total Hours: ${_formatHours(totalHours)}', style: const pw.TextStyle(fontSize: 14)),
                  ],
                ),
                if (logo != null)
                  pw.Container(
                    height: 50,
                    width: 50,
                    child: pw.Image(logo),
                  ),
              ],
            ),
          ),
          pw.SizedBox(height: 16),
          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
            children: [
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                children: [_buildTableHeader('Date'), _buildTableHeader('Hours'), _buildTableHeader('Details')],
              ),
              ...sortedEntries.map((e) => pw.TableRow(children: [
                _buildTableCell(DateFormat('MMM dd, yyyy').format(e.date)),
                _buildTableCell(_formatHours(e.workedHours)),
                _buildTableCell(e.details.isEmpty ? '-' : e.details, maxLines: 3),
              ])),
            ],
          ),
        ],
      ),
    );
    return pdf;
  }

  static pw.Widget _buildSummaryItem(String label, String value) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(label, style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
        pw.Text(value, style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
      ],
    );
  }

  static pw.Widget _buildTableHeader(String text) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(text, style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
    );
  }

  static pw.Widget _buildTableCell(String text, {int? maxLines}) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(text, style: const pw.TextStyle(fontSize: 10), maxLines: maxLines),
    );
  }

  static Future<void> previewRangeReport({
    required BuildContext context,
    required List<WorkEntry> entries,
    required String title,
    required String subtitle,
  }) async {
    try {
      final pdf = await generateRangePDF(entries: entries, title: title, subtitle: subtitle);
      final bytes = await pdf.save();
      await Printing.layoutPdf(onLayout: (format) async => bytes, name: title.replaceAll(' ', '_'));
    } catch (e) {
      if (context.mounted) _showError(context, e);
    }
  }

  static Future<void> shareRangeReport({
    required BuildContext context,
    required List<WorkEntry> entries,
    required String title,
    required String subtitle,
  }) async {
    try {
      final pdf = await generateRangePDF(entries: entries, title: title, subtitle: subtitle);
      final bytes = await pdf.save();
      await Printing.sharePdf(bytes: bytes, filename: '${title.replaceAll(' ', '_')}.pdf');
    } catch (e) {
      if (context.mounted) _showError(context, e);
    }
  }

  static Future<void> previewMonthlyReport({
    required BuildContext context,
    required List<WorkEntry> entries,
    required int year,
    required int month,
  }) async {
    try {
      final pdf = await generateMonthlyPDF(entries: entries, year: year, month: month);
      final bytes = await pdf.save();
      await Printing.layoutPdf(onLayout: (format) async => bytes, name: 'Report_${year}_$month');
    } catch (e) {
      if (context.mounted) _showError(context, e);
    }
  }

  static Future<void> shareMonthlyReport({
    required BuildContext context,
    required List<WorkEntry> entries,
    required int year,
    required int month,
  }) async {
    try {
      final pdf = await generateMonthlyPDF(entries: entries, year: year, month: month);
      final bytes = await pdf.save();
      await Printing.sharePdf(bytes: bytes, filename: 'Report_${year}_$month.pdf');
    } catch (e) {
      if (context.mounted) _showError(context, e);
    }
  }

  static Future<void> previewProjectReport({
    required BuildContext context,
    required List<WorkEntry> entries,
    required String projectName,
  }) async {
    try {
      final pdf = await _generateProjectPDF(entries: entries, projectName: projectName);
      final bytes = await pdf.save();
      await Printing.layoutPdf(onLayout: (format) async => bytes, name: projectName);
    } catch (e) {
      if (context.mounted) _showError(context, e);
    }
  }

  static Future<void> shareProjectReport({
    required BuildContext context,
    required List<WorkEntry> entries,
    required String projectName,
  }) async {
    try {
      final pdf = await _generateProjectPDF(entries: entries, projectName: projectName);
      final bytes = await pdf.save();
      await Printing.sharePdf(bytes: bytes, filename: '$projectName.pdf');
    } catch (e) {
      if (context.mounted) _showError(context, e);
    }
  }

  static void _showError(BuildContext context, dynamic e) {
    debugPrint('PDF Error: $e');
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
  }
}
