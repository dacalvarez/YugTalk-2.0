import 'dart:io';
import 'package:flutter/material.dart';
import 'package:gtext/gtext.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import 'Print_UtilsInterface.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform;

class PrintUtils implements PrintUtilsInterface {
  @override
  Future<void> savePdf(BuildContext context, pw.Document pdf, String fileName) async {
    try {
      final directory = await getTemporaryDirectory();
      final file = File('${directory.path}/$fileName');
      final pdfBytes = await pdf.save();
      await file.writeAsBytes(pdfBytes);

      if (!kIsWeb && Platform.isIOS) {
        final box = context.findRenderObject() as RenderBox?;
        await Share.shareXFiles(
          [XFile(file.path)],
          sharePositionOrigin: box!.localToGlobal(Offset.zero) & box.size,
        );
      } else {
        await Share.shareXFiles([XFile(file.path)]);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: GText('PDF export successfully')),
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
      final directory = await getTemporaryDirectory();
      final file = File('${directory.path}/$fileName');
      await file.writeAsBytes(bytes);

      if (!kIsWeb && Platform.isIOS) {
        final box = context.findRenderObject() as RenderBox?;
        await Share.shareXFiles(
          [XFile(file.path)],
          sharePositionOrigin: box!.localToGlobal(Offset.zero) & box.size,
        );
      } else {
        await Share.shareXFiles([XFile(file.path)]);
      }

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