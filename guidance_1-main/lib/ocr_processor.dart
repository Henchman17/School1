import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'config.dart';

class OCRSpaceUploader extends StatefulWidget {
  @override
  _OCRSpaceUploaderState createState() => _OCRSpaceUploaderState();
}

class _OCRSpaceUploaderState extends State<OCRSpaceUploader> {
  File? _selectedImage;
  String extractedText = "";

  Future<void> pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() => _selectedImage = File(pickedFile.path));
      await sendToOCRSpace(File(pickedFile.path));
    }
  }

  Future<void> sendToOCRSpace(File imageFile) async {
    const apiKey = "K83005968488957";
    const url = "https://api.ocr.space/parse/image";

    var request = http.MultipartRequest('POST', Uri.parse(url));

    request.fields['apikey'] = apiKey;
    request.fields['language'] = 'eng';
    request.fields['isOverlayRequired'] = 'false';

    request.files.add(
      await http.MultipartFile.fromPath('file', imageFile.path),
    );

    var response = await request.send();
    var responseBody = await response.stream.bytesToString();

    final jsonData = json.decode(responseBody);

    setState(() {
      extractedText = jsonData["ParsedResults"]?[0]["ParsedText"] ?? "No text found";
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("OCR.Space Flutter Demo")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            ElevatedButton(
              onPressed: pickImage,
              child: Text("Pick Image & Send to OCR"),
            ),
            SizedBox(height: 20),
            _selectedImage != null
                ? Image.file(_selectedImage!, height: 200)
                : Text("No image selected"),
            SizedBox(height: 20),
            Text("Extracted Text:", style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 10),
            Expanded(
              child: SingleChildScrollView(
                child: Text(extractedText),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
