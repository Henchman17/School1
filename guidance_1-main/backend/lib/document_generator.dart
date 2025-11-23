import 'dart:io';
import 'dart:convert';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path/path.dart' as path;

class BackendDocumentGenerator {
  static Future<String?> generateGoodMoralCertificate(
    int requestId,
    Map<String, dynamic> ocrData,
    String studentName,
    String studentNumber,
    String course,
    String yearLevel,
    String purpose,
  ) async {
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

                pw.Text('Name: $studentName'),
                pw.SizedBox(height: 10),

                pw.Text('Student ID: $studentNumber'),
                pw.SizedBox(height: 10),

                pw.Text('Course: $course'),
                pw.SizedBox(height: 10),

                pw.Text('Year Level: $yearLevel'),
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

                // Signature area
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.end,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.center,
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

      // Create documents directory if it doesn't exist
      final documentsDir = Directory('documents');
      if (!await documentsDir.exists()) {
        await documentsDir.create(recursive: true);
      }

      // Generate unique filename
      final fileName = 'good_moral_certificate_${requestId}_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final filePath = path.join(documentsDir.path, fileName);
      final file = File(filePath);

      // Save PDF
      await file.writeAsBytes(await pdf.save());

      return filePath;
    } catch (e) {
      print('Error generating PDF: $e');
      return null;
    }
  }
}
