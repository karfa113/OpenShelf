import 'dart:typed_data';

import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../models/book.dart';

class PdfService {
  static const _ink = PdfColor.fromInt(0xFF111111);
  static const _muted = PdfColor.fromInt(0xFF6B6B6B);
  static const _line = PdfColor.fromInt(0xFFE0E0E0);

  Future<Uint8List> generateLibraryManual(List<Book> books) async {
    final library = books.where((b) => !b.isTBR).toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    final tbr = books.where((b) => b.isTBR).toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

    // Load fonts for better aesthetics
    final titleFont = await PdfGoogleFonts.spaceGroteskBold();
    final headerFont = await PdfGoogleFonts.spaceGroteskMedium();
    final labelFont = await PdfGoogleFonts.spaceGroteskRegular();
    final bodyFont = await PdfGoogleFonts.interRegular();

    final doc = pw.Document(
      title: 'Library Manual',
      author: 'Library Manual App',
    );

    final now = DateTime.now();
    final dateStr = DateFormat('MMMM d, y').format(now);

    // Cover Page
    doc.addPage(pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(60),
      build: (ctx) {
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text('THE COLLECTED',
                style: pw.TextStyle(
                    font: headerFont,
                    fontSize: 12,
                    color: _muted,
                    letterSpacing: 4)),
            pw.SizedBox(height: 12),
            pw.Text('Library\nManual',
                style: pw.TextStyle(
                    font: titleFont,
                    fontSize: 72,
                    color: _ink,
                    height: 0.9)),
            pw.SizedBox(height: 32),
            pw.Container(
              height: 1,
              width: 80,
              color: _ink,
            ),
            pw.SizedBox(height: 32),
            pw.Text(
                'A comprehensive catalog of physical and digital volumes, tracked and organized for personal reference.',
                style: pw.TextStyle(
                    font: labelFont,
                    fontSize: 18,
                    color: _ink,
                    lineSpacing: 1.4)),
            pw.Spacer(),
            _statsGrid(library, tbr, headerFont, titleFont),
            pw.SizedBox(height: 60),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('GENERATED ON',
                        style: pw.TextStyle(
                            font: headerFont, fontSize: 8, color: _muted)),
                    pw.SizedBox(height: 4),
                    pw.Text(dateStr.toUpperCase(),
                        style: pw.TextStyle(
                            font: headerFont, fontSize: 10, color: _ink)),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text('EDITION',
                        style: pw.TextStyle(
                            font: headerFont, fontSize: 8, color: _muted)),
                    pw.SizedBox(height: 4),
                    pw.Text('1.0',
                        style: pw.TextStyle(
                            font: headerFont, fontSize: 10, color: _ink)),
                  ],
                ),
              ],
            ),
          ],
        );
      },
    ));

    // Library Table
    if (library.isNotEmpty) {
      doc.addPage(_tablePage(
        title: 'Library',
        count: library.length,
        books: library,
        includeRead: true,
        headerFont: headerFont,
        bodyFont: bodyFont,
        titleFont: titleFont,
      ));
    }

    // TBR Table
    if (tbr.isNotEmpty) {
      doc.addPage(_tablePage(
        title: 'To Be Read',
        count: tbr.length,
        books: tbr,
        includeRead: false,
        headerFont: headerFont,
        bodyFont: bodyFont,
        titleFont: titleFont,
      ));
    }

    return doc.save();
  }

  pw.MultiPage _tablePage({
    required String title,
    required int count,
    required List<Book> books,
    required bool includeRead,
    required pw.Font headerFont,
    required pw.Font bodyFont,
    required pw.Font titleFont,
  }) {
    return pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(40),
      header: (ctx) => _sectionHeader(title, '$count Items', titleFont, headerFont),
      footer: (ctx) => pw.Container(
        padding: const pw.EdgeInsets.only(top: 12),
        decoration: const pw.BoxDecoration(border: pw.Border(top: pw.BorderSide(color: _line, width: 0.5))),
        child: pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text('Library Manual', style: pw.TextStyle(font: headerFont, fontSize: 8, color: _muted)),
            pw.Text('Page ${ctx.pageNumber} / ${ctx.pagesCount}',
                style: pw.TextStyle(font: headerFont, fontSize: 8, color: _muted)),
          ],
        ),
      ),
      build: (ctx) => [
        pw.TableHelper.fromTextArray(
          border: null,
          headerStyle: pw.TextStyle(font: headerFont, fontSize: 8, color: _muted),
          headerDecoration: const pw.BoxDecoration(
            border: pw.Border(bottom: pw.BorderSide(color: _ink, width: 1.5)),
          ),
          cellStyle: pw.TextStyle(font: bodyFont, fontSize: 9, color: _ink),
          rowDecoration: const pw.BoxDecoration(
            border: pw.Border(bottom: pw.BorderSide(color: _line, width: 0.5)),
          ),
          cellPadding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          cellAlignments: {
            0: pw.Alignment.centerLeft,
            1: pw.Alignment.centerLeft,
            2: pw.Alignment.centerLeft,
            3: pw.Alignment.centerRight,
            4: pw.Alignment.centerRight,
          },
          headerAlignment: pw.Alignment.centerLeft,
          headers: includeRead
              ? ['TITLE', 'AUTHOR', 'PUBLISHER', 'PAGES', 'READ']
              : ['TITLE', 'AUTHOR', 'PUBLISHER', 'PAGES'],
          columnWidths: includeRead
              ? {
                  0: const pw.FlexColumnWidth(3),
                  1: const pw.FlexColumnWidth(2),
                  2: const pw.FlexColumnWidth(2),
                  3: const pw.FlexColumnWidth(1),
                  4: const pw.FlexColumnWidth(1.2),
                }
              : {
                  0: const pw.FlexColumnWidth(3),
                  1: const pw.FlexColumnWidth(2),
                  2: const pw.FlexColumnWidth(2),
                  3: const pw.FlexColumnWidth(1),
                },
          data: books.map((b) {
            final base = [
              b.name,
              b.author.isEmpty ? '—' : b.author,
              b.publisher.isEmpty ? '—' : b.publisher,
              b.pages == 0 ? '—' : '${b.pages}',
            ];
            if (!includeRead) return base;
            return [
              ...base,
              b.alreadyRead
                  ? (b.dateRead == null ? 'YES' : DateFormat('MM/yy').format(b.dateRead!))
                  : 'NO',
            ];
          }).toList(),
        ),
      ],
    );
  }

  pw.Widget _statsGrid(List<Book> lib, List<Book> tbr, pw.Font labelFont, pw.Font valFont) {
    final totalRead = lib.where((b) => b.alreadyRead).length;
    final totalPages = lib.where((b) => b.alreadyRead).fold<int>(0, (s, b) => s + b.pages);

    return pw.Row(
      children: [
        _statItem('VOLUMES', '${lib.length}', labelFont, valFont),
        pw.SizedBox(width: 40),
        _statItem('READ', '$totalRead', labelFont, valFont),
        pw.SizedBox(width: 40),
        _statItem('TBR', '${tbr.length}', labelFont, valFont),
        pw.SizedBox(width: 40),
        _statItem('PAGES', '$totalPages', labelFont, valFont),
      ],
    );
  }

  pw.Widget _statItem(String label, String value, pw.Font labelFont, pw.Font valFont) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(label, style: pw.TextStyle(font: labelFont, fontSize: 8, color: _muted, letterSpacing: 1.2)),
        pw.SizedBox(height: 4),
        pw.Text(value, style: pw.TextStyle(font: valFont, fontSize: 24, color: _ink)),
      ],
    );
  }

  pw.Widget _sectionHeader(String title, String subtitle, pw.Font titleFont, pw.Font subFont) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 24),
      padding: const pw.EdgeInsets.only(bottom: 12),
      decoration: const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(color: _ink, width: 2))),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        crossAxisAlignment: pw.CrossAxisAlignment.end,
        children: [
          pw.Text(title, style: pw.TextStyle(font: titleFont, fontSize: 32, color: _ink)),
          pw.Text(subtitle.toUpperCase(),
              style: pw.TextStyle(font: subFont, fontSize: 10, color: _muted, letterSpacing: 1.5)),
        ],
      ),
    );
  }
}
