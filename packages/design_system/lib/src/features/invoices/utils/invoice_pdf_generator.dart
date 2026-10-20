import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:domain/domain.dart';

/// Pure-Dart PDF 1.4 generator for formatted Invoice statements.
///
/// Produces a standards-compliant A4 vector PDF document with embedded
/// Type1 Helvetica / Helvetica-Bold typography, structured header, client
/// billing block, itemized line table, and financial summary totals.
class InvoicePdfGenerator {
  const InvoicePdfGenerator._();

  /// Generates raw PDF 1.4 bytes for [invoice].
  static Uint8List generatePdfBytes({
    required Invoice invoice,
    Client? client,
    String? preparedByUser,
    String? preparedByRole,
  }) {
    final contentStream = _buildPageContentStream(
      invoice: invoice,
      client: client,
      preparedByUser: preparedByUser,
      preparedByRole: preparedByRole,
    );
    final streamBytes = latin1.encode(contentStream);

    final objects = <int, List<int>>{};

    // 1: Catalog
    objects[1] = ascii.encode(
      '1 0 obj\n<< /Type /Catalog /Pages 2 0 R >>\nendobj\n',
    );

    // 2: Pages
    objects[2] = ascii.encode(
      '2 0 obj\n<< /Type /Pages /Kids [3 0 R] /Count 1 >>\nendobj\n',
    );

    // 3: Page (A4: 595 x 842 pt)
    objects[3] = ascii.encode(
      '3 0 obj\n'
      '<< /Type /Page /Parent 2 0 R /MediaBox [0 0 595 842]\n'
      '   /Resources << /Font << /F1 4 0 R /F2 5 0 R >> >>\n'
      '   /Contents 6 0 R\n'
      '>>\n'
      'endobj\n',
    );

    // 4: Font F1 (Helvetica Regular)
    objects[4] = ascii.encode(
      '4 0 obj\n'
      '<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica /Encoding /WinAnsiEncoding >>\n'
      'endobj\n',
    );

    // 5: Font F2 (Helvetica Bold)
    objects[5] = ascii.encode(
      '5 0 obj\n'
      '<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica-Bold /Encoding /WinAnsiEncoding >>\n'
      'endobj\n',
    );

    // 6: Page Content Stream
    final streamHeader = ascii.encode(
      '6 0 obj\n<< /Length ${streamBytes.length} >>\nstream\n',
    );
    final streamFooter = ascii.encode('\nendstream\nendobj\n');
    objects[6] = [...streamHeader, ...streamBytes, ...streamFooter];

    final out = BytesBuilder();
    out.add(ascii.encode('%PDF-1.4\n%\xE2\xE3\xCF\xD3\n'));

    final offsets = <int, int>{};
    for (var i = 1; i <= 6; i++) {
      offsets[i] = out.length;
      out.add(objects[i]!);
    }

    final xrefOffset = out.length;
    final xref = StringBuffer()
      ..writeln('xref')
      ..writeln('0 7')
      ..writeln('0000000000 65535 f ');
    for (var i = 1; i <= 6; i++) {
      final off = offsets[i]!.toString().padLeft(10, '0');
      xref.writeln('$off 00000 n ');
    }
    xref
      ..writeln('trailer')
      ..writeln('<< /Size 7 /Root 1 0 R >>')
      ..writeln('startxref')
      ..writeln('$xrefOffset')
      ..write('%%EOF');

    out.add(ascii.encode(xref.toString()));
    return out.toBytes();
  }

  /// Generates and writes the invoice PDF file to the user's Downloads folder
  /// (or the workspace `Invoices` directory as fallback), returning the saved file path.
  static Future<String> saveInvoicePdf({
    required Invoice invoice,
    Client? client,
    String? preparedByUser,
    String? preparedByRole,
  }) async {
    final bytes = generatePdfBytes(
      invoice: invoice,
      client: client,
      preparedByUser: preparedByUser,
      preparedByRole: preparedByRole,
    );

    final sanitizedNumber = invoice.number.replaceAll(
      RegExp(r'[^a-zA-Z0-9_\-]'),
      '_',
    );
    final fileName = 'Invoice_$sanitizedNumber.pdf';

    Directory targetDir;
    final userProfile =
        Platform.environment['USERPROFILE'] ?? Platform.environment['HOME'];
    if (userProfile != null && userProfile.isNotEmpty) {
      final downloadsDir = Directory('$userProfile${Platform.pathSeparator}Downloads');
      if (await downloadsDir.exists()) {
        targetDir = downloadsDir;
      } else {
        targetDir = Directory(
          '${Directory.current.path}${Platform.pathSeparator}Invoices',
        );
      }
    } else {
      targetDir = Directory(
        '${Directory.current.path}${Platform.pathSeparator}Invoices',
      );
    }

    if (!await targetDir.exists()) {
      await targetDir.create(recursive: true);
    }

    final file = File('${targetDir.path}${Platform.pathSeparator}$fileName');
    await file.writeAsBytes(bytes, flush: true);
    return file.path;
  }

  static String _escapePdfText(String input) {
    final asciiSafe = input
        .replaceAll('€', 'EUR ')
        .replaceAll('×', 'x')
        .replaceAll('·', '-')
        .replaceAll(r'\', r'\\')
        .replaceAll('(', r'\(')
        .replaceAll(')', r'\)');
    // Keep printable Latin-1 characters
    final codeUnits = asciiSafe.codeUnits.map((c) => (c >= 32 && c <= 255) ? c : 63);
    return String.fromCharCodes(codeUnits);
  }

  static String _buildPageContentStream({
    required Invoice invoice,
    Client? client,
    String? preparedByUser,
    String? preparedByRole,
  }) {
    final cmds = StringBuffer();
    final issueDate = (invoice.issuedAt ?? invoice.createdAt)
        .toIso8601String()
        .substring(0, 10);
    final statusLabel = invoice.status.name.toUpperCase();

    // Top Accent Header Banner (Royal Blue #1E40AF)
    cmds
      ..writeln('0.118 0.251 0.686 rg')
      ..writeln('40 742 515 62 re f')
      // Brand Title & Invoice Label inside Banner (White)
      ..writeln('1 1 1 rg')
      ..writeln('BT /F2 16 Tf 58 776 Td (DEBT MANAGER) Tj ET')
      ..writeln('BT /F1 9 Tf 58 760 Td (Ledger & Receivables Statement) Tj ET')
      ..writeln(
        'BT /F2 18 Tf 400 774 Td (${_escapePdfText(invoice.number)}) Tj ET',
      )
      ..writeln(
        'BT /F2 9 Tf 400 758 Td (STATUS: ${_escapePdfText(statusLabel)}) Tj ET',
      );

    // Billing & Metadata Section
    cmds
      ..writeln('0.39 0.45 0.55 rg')
      ..writeln('BT /F2 9 Tf 44 712 Td (BILL TO) Tj ET')
      ..writeln('BT /F2 9 Tf 380 712 Td (INVOICE DETAILS) Tj ET')
      ..writeln('0.08 0.10 0.14 rg')
      ..writeln(
        'BT /F2 12 Tf 44 695 Td (${_escapePdfText(client?.name ?? "Valued Client")}) Tj ET',
      );

    var clientY = 680;
    if (client?.phone != null && client!.phone!.isNotEmpty) {
      cmds.writeln(
        '0.30 0.35 0.42 rg BT /F1 10 Tf 44 $clientY Td (Phone: ${_escapePdfText(client.phone!)}) Tj ET',
      );
      clientY -= 14;
    }
    if (client?.notes != null && client!.notes!.isNotEmpty) {
      cmds.writeln(
        '0.30 0.35 0.42 rg BT /F1 10 Tf 44 $clientY Td (Notes: ${_escapePdfText(client.notes!)}) Tj ET',
      );
    }

    cmds
      ..writeln('0.30 0.35 0.42 rg')
      ..writeln(
        'BT /F1 10 Tf 380 695 Td (Date: ${_escapePdfText(issueDate)}) Tj ET',
      )
      ..writeln(
        'BT /F1 10 Tf 380 680 Td (Currency: ${_escapePdfText(invoice.currency.code)}) Tj ET',
      );
    if (preparedByUser != null && preparedByUser.isNotEmpty) {
      cmds.writeln(
        'BT /F1 9 Tf 380 665 Td (Prepared by: ${_escapePdfText(preparedByUser)} (${_escapePdfText(preparedByRole ?? "Staff")})) Tj ET',
      );
    }

    // Table Header Bar
    var y = 620;
    cmds
      ..writeln('0.94 0.96 0.98 rg')
      ..writeln('40 $y 515 24 re f')
      ..writeln('0.25 0.30 0.38 rg')
      ..writeln('BT /F2 9 Tf 50 ${y + 8} Td (#) Tj ET')
      ..writeln('BT /F2 9 Tf 80 ${y + 8} Td (DESCRIPTION) Tj ET')
      ..writeln('BT /F2 9 Tf 330 ${y + 8} Td (QTY) Tj ET')
      ..writeln('BT /F2 9 Tf 390 ${y + 8} Td (UNIT PRICE) Tj ET')
      ..writeln('BT /F2 9 Tf 480 ${y + 8} Td (LINE TOTAL) Tj ET');

    y -= 22;
    for (var i = 0; i < invoice.lines.length; i++) {
      if (y < 140) break; // Keep within single page bounds cleanly
      final line = invoice.lines[i];
      cmds
        ..writeln('0.10 0.12 0.16 rg')
        ..writeln('BT /F1 10 Tf 50 $y Td (${i + 1}) Tj ET')
        ..writeln(
          'BT /F1 10 Tf 80 $y Td (${_escapePdfText(line.description)}) Tj ET',
        )
        ..writeln('BT /F1 10 Tf 330 $y Td (x${line.quantity}) Tj ET')
        ..writeln(
          'BT /F1 10 Tf 390 $y Td (${_escapePdfText(line.unitPrice.format())}) Tj ET',
        )
        ..writeln(
          'BT /F2 10 Tf 480 $y Td (${_escapePdfText(line.lineTotal.format())}) Tj ET',
        )
        // Row separator line
        ..writeln('0.88 0.90 0.93 RG 0.6 w 40 ${y - 7} m 555 ${y - 7} l S');
      y -= 24;
    }

    // Totals Box
    final summaryTop = y - 16;
    cmds
      ..writeln('0.95 0.97 1.00 rg')
      ..writeln('340 ${summaryTop - 64} 215 68 re f')
      ..writeln('0.78 0.84 0.95 RG 0.8 w')
      ..writeln('340 ${summaryTop - 64} 215 68 re S')
      ..writeln('0.30 0.35 0.42 rg')
      ..writeln(
        'BT /F1 10 Tf 354 ${summaryTop - 18} Td (Gross Subtotal:) Tj ET',
      )
      ..writeln(
        'BT /F1 10 Tf 465 ${summaryTop - 18} Td (${_escapePdfText(invoice.grossTotal.format())}) Tj ET',
      )
      ..writeln(
        'BT /F1 10 Tf 354 ${summaryTop - 34} Td (Discount:) Tj ET',
      )
      ..writeln(
        'BT /F1 10 Tf 465 ${summaryTop - 34} Td (${_escapePdfText(invoice.discountTotal.format())}) Tj ET',
      )
      ..writeln('0.118 0.251 0.686 rg')
      ..writeln(
        'BT /F2 12 Tf 354 ${summaryTop - 54} Td (TOTAL DUE:) Tj ET',
      )
      ..writeln(
        'BT /F2 12 Tf 455 ${summaryTop - 54} Td (${_escapePdfText(invoice.total.format())}) Tj ET',
      );

    // Footer Note
    cmds
      ..writeln('0.50 0.55 0.62 rg')
      ..writeln(
        'BT /F1 8 Tf 40 42 Td (Generated by Debt Manager - Official Financial Statement) Tj ET',
      );

    return cmds.toString();
  }
}
