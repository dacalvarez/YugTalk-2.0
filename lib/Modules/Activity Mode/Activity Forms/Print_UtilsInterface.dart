import 'package:flutter/material.dart';
import 'package:pdf/widgets.dart' as pw;

abstract class PrintUtilsInterface {
  Future<void> savePdf(BuildContext context, pw.Document pdf, String fileName);
  Future<void> saveExcel(BuildContext context, List<int> bytes, String fileName);
}
