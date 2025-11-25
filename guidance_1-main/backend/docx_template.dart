import 'dart:convert';
import 'dart:io';
import 'package:docx_template/docx_template.dart';
import 'package:http/http.dart' as http;

Future<String> generateGoodMoralDocx(Map<String, dynamic> data) async {
  final file = File('templates/GoodMoral.docx');
  final bytes = await file.readAsBytes();
  final docx = await DocxTemplate.fromBytes(bytes);

  final content = Content();

  content
    ..add(TextContent("name", data["name"]))
    ..add(TextContent("course", data["course"]))
    ..add(TextContent("school_year", data["school_year"]))
    ..add(TextContent("day", data["day"]))
    ..add(TextContent("month_year", data["month_year"]))
    ..add(TextContent("purpose", data["purpose"]))
    ..add(TextContent("gor", data["gor"]))
    ..add(TextContent("date_of_payment", data["date_of_payment"]));

  final generated = await docx.generate(content);

  final outputFolder = Directory('generated');
  if (!outputFolder.existsSync()) outputFolder.createSync();

  final outputPath =
      "generated/good_moral_${DateTime.now().millisecondsSinceEpoch}.docx";

  final outFile = File(outputPath);
  await outFile.writeAsBytes(generated!);

  return outputPath;

}

Future<String> convertDocxToPdf(String docxPath) async {
  final apiKey = Platform.environment['CLOUDCONVERT_API_KEY'] ?? 'YOUR_API_KEY';
  final file = File(docxPath);
  final bytes = await file.readAsBytes();

  final response = await http.post(
    Uri.parse("https://api.cloudconvert.com/v2/convert"),
    headers: {
      "Authorization": "Bearer $apiKey",
      "Content-Type": "application/json",
    },
    body: jsonEncode({
      "input": "upload",
      "file": base64Encode(bytes),
      "filename": "good_moral.docx",
      "output_format": "pdf",
    }),
  );

  if (response.statusCode == 200) {
    final responseData = jsonDecode(response.body);
    final pdfUrl = responseData['data']['result']['files'][0]['url'];

    // Download the PDF
    final pdfResponse = await http.get(Uri.parse(pdfUrl));
    if (pdfResponse.statusCode == 200) {
      final pdfPath = docxPath.replaceAll('.docx', '.pdf');
      final pdfFile = File(pdfPath);
      await pdfFile.writeAsBytes(pdfResponse.bodyBytes);
      return pdfPath;
    } else {
      throw Exception('Failed to download PDF: ${pdfResponse.statusCode}');
    }
  } else {
    throw Exception('CloudConvert API error: ${response.statusCode} - ${response.body}');
  }
}
