import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';
import '../ocr_processor.dart';
import '../document_generator.dart';
import '../config.dart';

class GoodMoralRequest extends StatefulWidget {
  const GoodMoralRequest({super.key});

  @override
  State<GoodMoralRequest> createState() => _GoodMoralRequestState();
}

class _GoodMoralRequestState extends State<GoodMoralRequest> {
  String? _recognizedText;
  bool _isGeneratingDoc = false;
  Map<String, String> _extractedData = {};
  String _selectedIdType = 'UMID'; // Default ID type
  final List<String> _validIdTypes = ['UMID', 'PAGIBIG', 'TIN', 'Voter\'s ID', 'PhilHealth', 'SSS', 'Driver\'s License'];

  Future<void> _submitGoodMoralRequest(BuildContext context) async {
    if (_extractedData.isEmpty) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('No Data Available'),
          content: const Text('Please upload and process a valid ID first to extract your information.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }

    // Validate extracted data - now checking for name, address, signature
    if (!_validateExtractedIdData(_extractedData)) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Incomplete Data'),
          content: const Text('Required information (name, address, signature) could not be extracted from the ID. Please try uploading a clearer image.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }

    setState(() {
      _isGeneratingDoc = true;
    });

    try {
      // Get user ID from shared preferences
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt('user_id');
      if (userId == null) {
        throw Exception('User not logged in');
      }

      // Submit good moral request to Supabase
      await AppConfig.supabase.from('good_moral_requests').insert({
        'user_id': userId,
        'id_type': _selectedIdType,
        'ocr_data': _extractedData,
        'purpose': 'Good Moral Certificate Request',
        'status': 'pending',
        'created_at': DateTime.now().toIso8601String(),
      });

      setState(() {
        _isGeneratingDoc = false;
      });

      if (!context.mounted) return;

      // Clear extracted data after successful submission
      setState(() {
        _extractedData.clear();
        _recognizedText = null;
        _selectedIdType = 'UMID';
      });

      // Clear stored data
      await prefs.remove('ocr_extracted_data');

      // Show success message
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Success'),
          content: const Text('Your Good Moral Certificate request has been submitted successfully. You will be notified once it is reviewed by your guidance counselor.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } catch (e) {
      setState(() {
        _isGeneratingDoc = false;
      });
      if (!context.mounted) return;
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Error'),
          content: Text('Failed to submit request: $e'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  bool _validateExtractedIdData(Map<String, String> data) {
    // For ID validation, we need at least name, address, and signature
    return data.containsKey('name') &&
           data['name']!.isNotEmpty &&
           data.containsKey('address') &&
           data['address']!.isNotEmpty &&
           data.containsKey('signature') &&
           data['signature']!.isNotEmpty;
  }

  Future<void> _uploadAndProcessId(BuildContext context) async {
    final picker = ImagePicker();

    // Show ID type selection first
    final selectedIdType = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select ID Type'),
        content: DropdownButtonFormField<String>(
          value: _selectedIdType,
          items: _validIdTypes.map((type) => DropdownMenuItem(
            value: type,
            child: Text(type),
          )).toList(),
          onChanged: (value) {
            if (value != null) {
              setState(() {
                _selectedIdType = value;
              });
            }
          },
          decoration: const InputDecoration(
            labelText: 'ID Type',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(_selectedIdType),
            child: const Text('Continue'),
          ),
        ],
      ),
    );

    if (selectedIdType == null) return;

    // Show source selection dialog
    ImageSource? source;
    if (Platform.isAndroid) {
      source = await showDialog<ImageSource>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Select Image Source'),
          content: const Text('Choose where to get the ID image from:'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(ImageSource.camera),
              child: const Text('Camera'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(ImageSource.gallery),
              child: const Text('Gallery'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
          ],
        ),
      );
    } else {
      source = ImageSource.gallery;
    }

    if (source == null) return;

    final pickedFile = await picker.pickImage(
      source: source,
      imageQuality: 90, // Good quality for OCR
      maxWidth: 1920, // Reasonable size
      maxHeight: 1080,
    );

    if (pickedFile == null) return;

    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Text('Processing ID...'),
          ],
        ),
      ),
    );

    try {
      final imageFile = File(pickedFile.path);

      // Validate image
      final isValid = await OcrProcessor.isImageValid(imageFile);
      if (!isValid) {
        throw Exception('Invalid image file');
      }

      // Process OCR for ID document
      final extractedData = await OcrProcessor.processIdDocument(imageFile, selectedIdType);

      if (!context.mounted) return;

      // Close loading dialog
      Navigator.of(context).pop();

      // Check if required fields were extracted
      if (!_validateExtractedIdData(extractedData)) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Incomplete Data'),
            content: const Text('Required information (name, address, signature) could not be extracted from the ID. Please ensure the image is clear and contains all required information, then try again.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
        );
        return;
      }

      setState(() {
        _extractedData = extractedData;
        _recognizedText = extractedData.values.join('\n');
      });

      // Save extracted data to local storage
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('ocr_extracted_data', extractedData.toString());

      // Show extracted data for confirmation
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Confirm Extracted ID Data'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('ID Type: $selectedIdType'),
                const SizedBox(height: 8),
                const Text('Extracted Information:'),
                const SizedBox(height: 8),
                ...extractedData.entries.map((entry) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Text('${entry.key}: ${entry.value}'),
                  );
                }),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
            TextButton(
              onPressed: () => _editExtractedIdData(context, extractedData),
              child: const Text('Edit'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!context.mounted) return;

      // Close loading dialog
      Navigator.of(context).pop();

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Error'),
          content: Text('Failed to process ID: $e'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    }
  }
  


  Future<Map<String, String>> _loadExtractedData() async {
    final prefs = await SharedPreferences.getInstance();
    final dataString = prefs.getString('ocr_extracted_data');
    if (dataString != null) {
      // Parse the string back to map (simplified parsing)
      final Map<String, String> data = {};
      final entries = dataString.replaceAll('{', '').replaceAll('}', '').split(', ');
      for (final entry in entries) {
        final parts = entry.split(': ');
        if (parts.length == 2) {
          data[parts[0]] = parts[1];
        }
      }
      return data;
    }
    return {};
  }

  void _editExtractedIdData(BuildContext context, Map<String, String> extractedData) {
    // Close the current dialog
    Navigator.of(context).pop();

    // Create controllers for each field
    final nameController = TextEditingController(text: extractedData['name'] ?? '');
    final addressController = TextEditingController(text: extractedData['address'] ?? '');
    final signatureController = TextEditingController(text: extractedData['signature'] ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Extracted ID Data'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Full Name'),
              ),
              TextField(
                controller: addressController,
                decoration: const InputDecoration(labelText: 'Address'),
              ),
              TextField(
                controller: signatureController,
                decoration: const InputDecoration(labelText: 'Signature'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              // Update the extracted data
              final updatedData = {
                'name': nameController.text,
                'address': addressController.text,
                'signature': signatureController.text,
              };

              setState(() {
                _extractedData = updatedData;
                _recognizedText = updatedData.values.join('\n');
              });

              // Save updated data to local storage
              SharedPreferences.getInstance().then((prefs) {
                prefs.setString('ocr_extracted_data', updatedData.toString());
              });

              Navigator.of(context).pop();

              // Show confirmation
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Data Updated'),
                  content: const Text('The extracted ID data has been updated successfully.'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('OK'),
                    ),
                  ],
                ),
              );
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _loadExtractedData().then((value) {
      setState(() {
        _extractedData = value;
        _recognizedText = value.values.join('\n');
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.verified_user, color: Colors.white, size: 28),
            const SizedBox(width: 8),
            const Text(
              "Request of Good Moral",
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        backgroundColor: const Color.fromARGB(255, 30, 182, 88),
        elevation: 4,
        shadowColor: Colors.green.shade900.withOpacity(0.3),
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
          SingleChildScrollView( // Wrap with SingleChildScrollView
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 320,
                      height: 180,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.blue.shade50, Colors.blue.shade100, Colors.blue.shade200],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.blue.shade400, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.blue.shade300.withOpacity(0.4),
                            blurRadius: 12,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(20),
                        onTap: () => _uploadAndProcessId(context),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.upload_file, size: 64, color: Colors.blue.shade800),
                            const SizedBox(height: 16),
                            Text(
                              'Upload Valid ID',
                              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blue.shade900),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    Container(
                      width: 320,
                      height: 180,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.green.shade50, Colors.green.shade100, Colors.green.shade200],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.green.shade400, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.green.shade300.withOpacity(0.4),
                            blurRadius: 12,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(20),
                        onTap: () => _uploadAndProcessId(context),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.camera_alt, size: 64, color: Colors.green.shade800),
                            const SizedBox(height: 16),
                            Text(
                              'Capture ID Photo',
                              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.green.shade900),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (_recognizedText != null) ...[
                      const SizedBox(height: 32),
                      Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Last Recognized Text:',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                              const SizedBox(height: 8),
                              SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Text(
                                  _recognizedText ?? '',
                                  style: const TextStyle(fontSize: 14),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                      Container(
                        width: 320,
                        height: 180,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.purple.shade50, Colors.purple.shade100, Colors.purple.shade200],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.purple.shade400, width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.purple.shade300.withOpacity(0.4),
                              blurRadius: 12,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(20),
                          onTap: () => _submitGoodMoralRequest(context),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _isGeneratingDoc
                                  ? const CircularProgressIndicator(color: Colors.purple)
                                  : Icon(Icons.send, size: 64, color: Colors.purple.shade800),
                              const SizedBox(height: 16),
                              Text(
                                _isGeneratingDoc ? 'Submitting...' : 'Submit Good Moral Request',
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.purple.shade900),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
