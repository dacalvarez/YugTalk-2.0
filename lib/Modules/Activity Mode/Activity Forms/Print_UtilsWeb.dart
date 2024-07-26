import 'package:gtext/gtext.dart';
import 'package:universal_html/html.dart' as html;
import 'package:flutter/material.dart';
import 'package:pdf/widgets.dart' as pw;
import 'Print_UtilsInterface.dart';

class PrintUtils implements PrintUtilsInterface {
  @override
  Future<void> savePdf(BuildContext context, pw.Document pdf, String fileName) async {
    try {
      final bytes = await pdf.save();
      final blob = html.Blob([bytes]);
      final url = html.Url.createObjectUrlFromBlob(blob);
      final anchor = html.AnchorElement(href: url)
        ..setAttribute("download", fileName)
        ..click();
      html.Url.revokeObjectUrl(url);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: GText('PDF exported successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: GText('Failed to export PDF: ${e.toString()}')),
      );
    }
  }

  @override
  Future<void> saveExcel(BuildContext context, List<int> bytes, String fileName) async {
    try {
      final blob = html.Blob([bytes], 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet');
      final url = html.Url.createObjectUrlFromBlob(blob);
      final anchor = html.AnchorElement(href: url)
        ..setAttribute("download", fileName)
        ..click();
      html.Url.revokeObjectUrl(url);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: GText('Excel file exported successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: GText('Failed to export Excel: ${e.toString()}')),
      );
    }
  }
}