import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:open_file/open_file.dart';

class DocumentGenerator {
  static Future<File?> generateGoodMoralPDF(Map<String, String> ocrData) async {
    try {
      final pdf = pw.Document();

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: pw.EdgeInsets.all(50),
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Header
                pw.Center(
                  child: pw.Text(
                    'GOOD MORAL CERTIFICATE',
                    style: pw.TextStyle(
                      fontSize: 20,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
                pw.SizedBox(height: 30),

                // Student Information
                pw.Text('TO WHOM IT MAY CONCERN:',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 20),

                pw.Text('This is to certify that:'),
                pw.SizedBox(height: 15),

                pw.Text('Name: ${ocrData['studentName'] ?? '____________________'}'),
                pw.SizedBox(height: 10),

                pw.Text('Student ID: ${ocrData['studentId'] ?? '____________________'}'),
                pw.SizedBox(height: 10),

                pw.Text('Course: ${ocrData['course'] ?? '____________________'}'),
                pw.SizedBox(height: 10),

                pw.Text('Year Level: ${ocrData['yearLevel'] ?? '____________________'}'),
                pw.SizedBox(height: 20),

                // Certificate body
                pw.Text(
                  'has been a student of this institution and has shown exemplary conduct '
                  'and behavior during their stay. They have not been involved in any '
                  'disciplinary actions and have maintained good moral character.',
                  textAlign: pw.TextAlign.justify,
                ),
                pw.SizedBox(height: 30),

                pw.Text('Given this ${DateTime.now().day}th day of ${DateTime.now().month}, ${DateTime.now().year}.'),
                pw.SizedBox(height: 40),

                // Signature section
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('___________________________'),
                        pw.Text('Guidance Counselor'),
                      ],
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('___________________________'),
                        pw.Text('School Director'),
                      ],
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      );

      // Get directory based on platform
      final directory = await _getDocumentDirectory();
      final fileName = 'good_moral_certificate_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final file = File('${directory.path}/$fileName');

      // Save PDF
      await file.writeAsBytes(await pdf.save());

      return file;
    } catch (e) {
      print('Error generating PDF: $e');
      return null;
    }
  }

  static Future<Directory> _getDocumentDirectory() async {
    if (Platform.isAndroid) {
      // Try to use Downloads folder on Android
      final downloadsDir = Directory('/storage/emulated/0/Download');
      if (await downloadsDir.exists()) {
        return downloadsDir;
      }

      // Fallback to external storage
      final externalDir = await getExternalStorageDirectory();
      if (externalDir != null) {
        return externalDir;
      }
    }

    // For other platforms or fallback
    final appDocDir = await getApplicationDocumentsDirectory();
    return appDocDir;
  }

  static Future<bool> requestStoragePermission() async {
    if (Platform.isAndroid) {
      final status = await Permission.storage.request();
      if (status.isGranted) {
        return true;
      }

      // Try to request manage external storage permission
      final manageStatus = await Permission.manageExternalStorage.request();
      return manageStatus.isGranted;
    }

    return true; // Assume granted for other platforms
  }

  static Future<void> openDocument(File file) async {
    try {
      final result = await OpenFile.open(file.path);
      if (result.type != ResultType.done) {
        print('Error opening file: ${result.message}');
      }
    } catch (e) {
      print('Error opening document: $e');
    }
  }

  static bool validateOcrData(Map<String, String> data) {
    final requiredFields = ['studentName', 'studentId', 'course'];
    return requiredFields.every((field) =>
        data.containsKey(field) &&
        data[field]?.isNotEmpty == true &&
        data[field] != null);
  }
}
