import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'download_request_slip.dart';

class GoodMoralRequest extends StatelessWidget {
  const GoodMoralRequest({super.key});

  void _navigateToDownloadRequestSlip(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const DownloadRequestSlip(),
      ),
    );
  }

  Future<void> _pickAndRecognizeText(BuildContext context) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile == null) return;

    final recognizedText = await compute(recognizeTextInImage, pickedFile.path);

    if (!context.mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Recognized Text'),
        content: SingleChildScrollView(child: Text(recognizedText)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  static Future<String> recognizeTextInImage(String imagePath) async {
    final inputImage = InputImage.fromFilePath(imagePath);
    final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
    final RecognizedText recognizedText = await textRecognizer.processImage(inputImage);
    textRecognizer.close();
    return recognizedText.text;
  }
  
  void _navigateToCaptureRequestSlip(BuildContext context) {
    _pickAndRecognizeText(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Good Moral Request'),
        backgroundColor: const Color.fromARGB(255, 30, 182, 88),
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.lightGreen.withOpacity(0.3),
                    Colors.green.shade900.withOpacity(1.0),
                  ],
                ),
              ),
            ),
          ),
          Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 300,
                    child: Card(
                      elevation: 4,
                      child: InkWell(
                        onTap: () => _navigateToDownloadRequestSlip(context),
                        child: SizedBox(
                          height: 150,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Icon(Icons.download, size: 48, color: Colors.blue),
                              SizedBox(height: 12),
                              Text(
                                'Download Request Slip',
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: 300,
                    child: Card(
                      elevation: 4,
                      child: InkWell(
                        onTap: () => _navigateToCaptureRequestSlip(context),
                        child: SizedBox(
                          height: 150,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Icon(Icons.camera_alt, size: 48, color: Colors.green),
                              SizedBox(height: 12),
                              Text(
                                'Capture Request Slip',
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
