import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'package:provider/provider.dart';
import 'package:image/image.dart' as img;
import '../config.dart';
import '../providers/form_settings_provider.dart';

// OCR Processing Service
class OcrProcessor {
  static const String _apiKey = AppConfig.OCR_API_KEY;
  static const String _apiUrl = AppConfig.OCR_API_URL;
  
  static Future<bool> isImageValid(File imageFile) async {
    if (!await imageFile.exists()) return false;
    final extension = imageFile.path.split('.').last.toLowerCase();
    return ['jpg', 'jpeg', 'png', 'bmp', 'tiff'].contains(extension);
  }

  static Future<Map<String, String>> processRequestSlip(File imageFile) async {
    final request = http.MultipartRequest('POST', Uri.parse(_apiUrl))
      ..fields['apikey'] = _apiKey
      ..fields['language'] = 'eng'
      ..fields['isOverlayRequired'] = 'false'
      ..fields['OCREngine'] = '2'  // Try engine 2 (more accurate)
      ..fields['scale'] = 'true'    // Auto-scale image
      ..fields['isTable'] = 'true'  // Better for forms
      ..files.add(await http.MultipartFile.fromPath('file', imageFile.path));

    final response = await request.send();
    final responseBody = await response.stream.bytesToString();

    print('OCR API Response Status: ${response.statusCode}');
    print('OCR API Response Body: $responseBody');

    if (response.statusCode != 200) {
      throw Exception('OCR API request failed with status ${response.statusCode}: $responseBody');
    }

    final jsonData = json.decode(responseBody);

    // Check for API errors
    if (jsonData.containsKey('ErrorMessage')) {
      throw Exception('OCR API Error: ${jsonData['ErrorMessage']}');
    }

    if (jsonData.containsKey('OCRExitCode') && jsonData['OCRExitCode'] != 1) {
      throw Exception('OCR processing failed with exit code: ${jsonData['OCRExitCode']}');
    }

    final extractedText = jsonData["ParsedResults"]?[0]?["ParsedText"] ?? "";

    if (extractedText.isEmpty) {
      throw Exception('No text was extracted from the image. Please ensure the image is clear and contains readable text.');
    }

    print('Extracted Text: $extractedText');

    return _parseSlipText(extractedText);
  }

  static Map<String, String> _parseSlipText(String text) {
    final data = {
      'name': '',
      'address': '',
      'course': '',
      'date': '',
      'purpose': '',
      'school_year': '',
    };

    // Clean and split text into lines
    final lines = text.split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();

    // Find where the actual form data starts (skip header/title sections)
    int dataStartIndex = 0;
    for (int i = 0; i < lines.length; i++) {
      final lowerLine = lines[i].toLowerCase();
      // Look for common field indicators that mark the start of the form data
      if (lowerLine.contains('date requested') || 
          lowerLine.contains('last attendance') ||
          lowerLine.contains('last attendace') || // typo in form
          lowerLine.contains('name:') || 
          lowerLine.contains('student name')) {
        dataStartIndex = i;
        break;
      }
    }

    // Parse only from the data section onwards
    for (int i = dataStartIndex; i < lines.length; i++) {
      final line = lines[i];
      final lowerLine = line.toLowerCase();

      // Extract date requested
      if ((lowerLine.contains('date requested') || lowerLine.contains('date:')) && data['date']!.isEmpty) {
        // Try to extract date value after colon or "requested"
        if (line.contains(':')) {
          data['date'] = line.split(':').last.trim();
        } else {
          data['date'] = line.replaceAll(RegExp(r'date requested[:\s]*', caseSensitive: false), '').trim();
        }
        // If next line doesn't contain a field label, it might be the date value
        if (data['date']!.isEmpty && i + 1 < lines.length) {
          final nextLine = lines[i + 1].toLowerCase();
          if (!nextLine.contains('name') && !nextLine.contains('address') && 
              !nextLine.contains('grade/course/course') && !nextLine.contains('purpose')) {
            data['date'] = lines[i + 1].trim();
          }
        }
      }
      // Extract name
      else if ((lowerLine.contains('name') || lowerLine.contains('student name')) && data['name']!.isEmpty) {
        if (line.contains(':')) {
          data['name'] = line.split(':').last.trim();
        } else {
          data['name'] = line.replaceAll(RegExp(r'(name|student name)[:\s]*', caseSensitive: false), '').trim();
        }
        // If name is empty, check next line
        if (data['name']!.isEmpty && i + 1 < lines.length) {
          final nextLine = lines[i + 1].toLowerCase();
          if (!nextLine.contains('address') && !nextLine.contains('course') &&
              !nextLine.contains('purpose') && !nextLine.contains('date')) {
            data['name'] = lines[i + 1].trim();
          }
        }
      }
      // Extract address
      else if (lowerLine.contains('address') && data['address']!.isEmpty) {
        if (line.contains(':')) {
          data['address'] = line.split(':').last.trim();
        } else {
          data['address'] = line.replaceAll(RegExp(r'address[:\s]*', caseSensitive: false), '').trim();
        }
        // If address is empty, check next line
        if (data['address']!.isEmpty && i + 1 < lines.length) {
          final nextLine = lines[i + 1].toLowerCase();
          if (!nextLine.contains('name') && !nextLine.contains('course') && 
              !nextLine.contains('purpose') && !nextLine.contains('date')) {
            data['address'] = lines[i + 1].trim();
          }
        }
      }
      // Extract course
      else if (lowerLine.contains('course') && data['course']!.isEmpty) {
        if (line.contains(':')) {
          data['course'] = line.split(':').last.trim();
        } else {
          data['course'] = line.replaceAll(RegExp(r'course[:\s]*', caseSensitive: false), '').trim();
        }
        // If course is empty, check next line
        if (data['course']!.isEmpty && i + 1 < lines.length) {
          final nextLine = lines[i + 1].toLowerCase();
          if (!nextLine.contains('name') && !nextLine.contains('address') && 
              !nextLine.contains('purpose') && !nextLine.contains('date') &&
              !nextLine.contains('last attendance')) {
            data['course'] = lines[i + 1].trim();
          }
        }
      }
      // Extract school year (Last Attendance) - Process BEFORE purpose
      else if ((lowerLine.contains('last attendance') || 
                lowerLine.contains('last attendace') || // typo in form
                lowerLine.contains('s.y/sem') || 
                lowerLine.contains('s.y') && lowerLine.contains('sem')) && 
               data['school_year']!.isEmpty) {
        if (line.contains(':')) {
          data['school_year'] = line.split(':').last.trim();
        } else {
          data['school_year'] = line.replaceAll(RegExp(r'last attenda[cn]ce\s*\(s\.y/sem\)[:\s]*', caseSensitive: false), '').trim();
        }
        // If school year is empty, check next line
        if (data['school_year']!.isEmpty && i + 1 < lines.length) {
          final nextLine = lines[i + 1].toLowerCase();
          if (!nextLine.contains('name') && !nextLine.contains('address') && 
              !nextLine.contains('course') && !nextLine.contains('date') &&
              !nextLine.contains('purpose')) {
            data['school_year'] = lines[i + 1].trim();
          }
        }
      }
      // Extract purpose - look for various possible labels
      else if ((lowerLine.contains('purpose') ||
                lowerLine.contains('reason') ||
                lowerLine.contains('for what purpose') ||
                lowerLine.contains('intended for')) && data['purpose']!.isEmpty) {
        if (line.contains(':')) {
          data['purpose'] = line.split(':').last.trim();
        } else {
          data['purpose'] = line.replaceAll(RegExp(r'(purpose|reason|for what purpose|intended for)[:\s]*', caseSensitive: false), '').trim();
        }
        // If purpose is empty, check next line(s) - purpose might span multiple lines
        if (data['purpose']!.isEmpty && i + 1 < lines.length) {
          final nextLine = lines[i + 1].toLowerCase();
          if (!nextLine.contains('name') && !nextLine.contains('address') &&
              !nextLine.contains('course') && !nextLine.contains('date') &&
              !nextLine.contains('last attendance') && !nextLine.contains('cellphone') &&
              !nextLine.contains('check') && !nextLine.contains('signature') &&
              !nextLine.contains('undergraduate') && !nextLine.contains('graduate')) {
            data['purpose'] = lines[i + 1].trim();
            // Check one more line if purpose spans multiple lines
            if (i + 2 < lines.length && (data['purpose']?.length ?? 0) < 10) {
              final nextNextLine = lines[i + 2].toLowerCase();
              if (!nextNextLine.contains('name') && !nextNextLine.contains('address') &&
                  !nextNextLine.contains('course') && !nextNextLine.contains('date') &&
                  !nextNextLine.contains('last attendance') && !nextNextLine.contains('cellphone') &&
                  !nextNextLine.contains('check') && !nextNextLine.contains('signature') &&
                  !nextNextLine.contains('undergraduate') && !nextNextLine.contains('graduate')) {
                data['purpose'] = (data['purpose'] ?? '') + ' ' + lines[i + 2].trim();
              }
            }
          }
        }
      }
      // Alternative: Look for purpose after the "Kindly Check" section
      else if (lowerLine.contains('kindly check') && data['purpose']!.isEmpty) {
        // Look for purpose in the lines after the check section
        for (int j = i + 1; j < lines.length && j < i + 10; j++) { // Check next 10 lines
          final checkLine = lines[j].toLowerCase();
          if ((checkLine.contains('purpose') || checkLine.contains('reason') ||
               checkLine.contains('for what purpose') || checkLine.contains('intended for'))) {
            if (lines[j].contains(':')) {
              data['purpose'] = lines[j].split(':').last.trim();
            } else {
              data['purpose'] = lines[j].replaceAll(RegExp(r'(purpose|reason|for what purpose|intended for)[:\s]*', caseSensitive: false), '').trim();
            }
            break;
          }
          // If we find a line that doesn't contain form field keywords, it might be the purpose
          else if (!checkLine.contains('name') && !checkLine.contains('address') &&
                   !checkLine.contains('course') && !checkLine.contains('date') &&
                   !checkLine.contains('last attendance') && !checkLine.contains('cellphone') &&
                   !checkLine.contains('signature') && !checkLine.contains('undergraduate') &&
                   !checkLine.contains('graduate') && lines[j].trim().isNotEmpty) {
            data['purpose'] = lines[j].trim();
            break;
          }
        }
      }
    }

    print('Parsed data: $data');
    return data;
  }
}

// Main Widget
class GoodMoralRequest extends StatefulWidget {
  const GoodMoralRequest({super.key});

  @override
  State<GoodMoralRequest> createState() => _GoodMoralRequestState();
}

class _GoodMoralRequestState extends State<GoodMoralRequest> {
  // State variables
  int _currentStep = 0;
  File? _uploadedImage;
  Map<String, String> _extractedData = {};
  bool _isProcessing = false;
  Map<String, dynamic>? _currentRequest;
  bool _isCheckingStatus = false;

  final List<String> _steps = [
    'Download Form',
    'Upload/Capture',
    'Process OCR',
    'Review Data',
    'Submit Request'
  ];

  @override
  void initState() {
    super.initState();
    _loadSavedData();
  }

  // Data Management
  Future<void> _loadSavedData() async {
    final prefs = await SharedPreferences.getInstance();
    final dataString = prefs.getString('ocr_extracted_data');
    
    if (dataString != null) {
      final data = <String, String>{};
      final entries = dataString.replaceAll('{', '').replaceAll('}', '').split(', ');
      
      for (final entry in entries) {
        final parts = entry.split(': ');
        if (parts.length == 2) {
          data[parts[0]] = parts[1];
        }
      }
      
      setState(() => _extractedData = data);
    }
  }

  Future<void> _saveData(Map<String, String> data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('ocr_extracted_data', data.toString());
  }

  Future<void> _clearAllData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('ocr_extracted_data');

    setState(() {
      _extractedData.clear();
      _uploadedImage = null;
      _currentRequest = null;
    });
  }

  Future<void> _checkCurrentRequestStatus() async {
    setState(() {
      _isCheckingStatus = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt('user_id');

      if (userId == null) return;

      final apiUrl = await AppConfig.apiBaseUrl;
      final response = await http.get(
        Uri.parse('$apiUrl/api/student/good-moral-requests/approval_status?user_id=$userId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _currentRequest = data['request'];
          _isCheckingStatus = false;
        });
      } else {
        setState(() {
          _currentRequest = null;
          _isCheckingStatus = false;
        });
      }
    } catch (e) {
      setState(() {
        _currentRequest = null;
        _isCheckingStatus = false;
      });
    }
  }

  bool _validateData(Map<String, String> data) {
    return data['name']?.isNotEmpty == true &&
           data['address']?.isNotEmpty == true &&
           data['course']?.isNotEmpty == true &&
           data['date']?.isNotEmpty == true &&
           data['purpose']?.isNotEmpty == true &&
           data['school_year']?.isNotEmpty == true;
  }

  // Image Handling
  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: source,
      imageQuality: 85,
      maxWidth: 1600,
      maxHeight: 1200,
    );

    if (pickedFile == null) return;

    setState(() => _uploadedImage = File(pickedFile.path));
    _showSuccessDialog('Image Uploaded', 'Image uploaded successfully. You can now process it with OCR.');
  }

  Future<void> _processImageWithOCR() async {
    if (_uploadedImage == null) {
      _showWarningDialog('No Image', 'Please upload or capture an image first.');
      return;
    }

    _showLoadingDialog('Processing with OCR...');

    try {
      final isValid = await OcrProcessor.isImageValid(_uploadedImage!);
      if (!isValid) throw Exception('Invalid image file');

      final extractedData = await OcrProcessor.processRequestSlip(_uploadedImage!);
      
      if (!mounted) return;
      Navigator.of(context).pop(); // Close loading dialog

      if (!_validateData(extractedData)) {
        _showErrorDialog(
          'Extraction Failed',
          'Required information could not be extracted. Please ensure the image is clear and contains all required fields (name, address, course, date, purpose, last attendance).',
        );
        return;
      }

      setState(() => _extractedData = extractedData);
      await _saveData(extractedData);
      _showExtractedDataDialog(extractedData);
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context).pop(); // Close loading dialog
      _showErrorDialog('Processing Failed', 'Failed to process request slip: $e');
    }
  }

  // Request Submission
  Future<void> _submitGoodMoralRequest() async {
  if (_extractedData.isEmpty) {
    _showWarningDialog(
      'No Data Available',
      'Please upload and process a request slip first.',
    );
    return;
  }

  if (!_validateData(_extractedData)) {
    _showWarningDialog(
      'Incomplete Data',
      'Required information is missing. Please provide all required fields.',
    );
    return;
  }

  setState(() => _isProcessing = true);

  try {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('user_id');
    
    if (userId == null) throw Exception('User not logged in');

    final baseUrl = await AppConfig.apiBaseUrl;
    final requestUrl = '$baseUrl/api/student/good-moral-requests';
    
    print('DEBUG: Submitting to URL: $requestUrl');
    print('DEBUG: Student ID: $userId');
    
    final response = await http.post(
      Uri.parse(requestUrl),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'student_id': userId,
        'student_name': _extractedData['name'],
        'course': _extractedData['course'],
        'purpose': _extractedData['purpose'],
        'ocr_data': _extractedData,
        'approval_status': 'pending',
        'address': _extractedData['address'],
        'school_year': _extractedData['school_year'],
      }),
    );

    print('DEBUG: Response status: ${response.statusCode}');
    print('DEBUG: Response body: ${response.body}');

    setState(() => _isProcessing = false);

    if (!mounted) return;

    if (response.statusCode == 200 || response.statusCode == 201) {
      await _clearAllData();
      _showSuccessDialog(
        'Request Submitted',
        'Your Good Moral Certificate request has been submitted successfully. You will be notified once it is reviewed.',
      );
    } else {
      String errorMessage = 'Failed to submit request';
      try {
        final errorData = jsonDecode(response.body);
        errorMessage = errorData['error'] ?? errorData['message'] ?? errorMessage;
      } catch (e) {
        errorMessage = response.body.isNotEmpty ? response.body : 'Server returned status ${response.statusCode}';
      }
      throw Exception(errorMessage);
    }
  } catch (e) {
    setState(() => _isProcessing = false);
    if (!mounted) return;
    
    print('DEBUG: Error occurred: $e');
    _showErrorDialog('Error', 'Failed to submit request: $e');
  }
}

  // Request Slip Download
  Future<void> _downloadRequestSlip() async {
    setState(() => _isProcessing = true);

    try {
      final data = await rootBundle.load('assets/files/RequestSlip.docx');
      final bytes = data.buffer.asUint8List();
      final directory = await getApplicationDocumentsDirectory();
      final fileName = 'request_slip_${DateTime.now().millisecondsSinceEpoch}.docx';
      final file = File('${directory.path}/$fileName');

      await file.writeAsBytes(bytes);
      final result = await OpenFile.open(file.path);

      if (result.type != ResultType.done) {
        throw Exception('Failed to open file: ${result.message}');
      }

      setState(() => _isProcessing = false);
      _showSuccessDialog(
        'Request Slip Downloaded',
        'The request slip has been downloaded and opened. Please fill it out and proceed with uploading.',
      );
    } catch (e) {
      setState(() => _isProcessing = false);
      _showErrorDialog('Download Failed', 'Failed to download request slip: $e');
    }
  }

  // UI Helper Methods
  Widget _buildTextField(TextEditingController controller, String label, {int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(labelText: label),
        maxLines: maxLines,
      ),
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required List<Color> gradientColors,
    required Color iconColor,
    bool showLoading = false,
    bool isCompleted = false,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: showLoading ? null : onTap,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              colors: gradientColors,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: iconColor.withOpacity(0.1),
                  border: Border.all(color: iconColor, width: 2),
                ),
                child: showLoading
                    ? CircularProgressIndicator(color: iconColor)
                    : Icon(icon, size: 30, color: iconColor),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: iconColor,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: iconColor.withOpacity(0.8),
                ),
                textAlign: TextAlign.center,
              ),
              if (isCompleted) ...[
                const SizedBox(height: 8),
                Icon(Icons.check_circle, color: Colors.green, size: 20),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepContent() {
    switch (_currentStep) {
      case 0:
        return _buildStep1Download();
      case 1:
        return _buildStep2Upload();
      case 2:
        return _buildStep3Process();
      case 3:
        return _buildStep4Review();
      case 4:
        return _buildStep5Submit();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildStep1Download() {
    return Column(
      children: [
        const Text(
          'Step 1: Download Request Form',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        const Text(
          'First, download the official request slip form. Fill it out completely with all required information.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
        const SizedBox(height: 32),
        _buildActionCard(
          icon: Icons.download,
          title: 'Download Form',
          subtitle: 'Get the official request slip',
          onTap: _downloadRequestSlip,
          gradientColors: [Colors.teal.shade50, Colors.teal.shade100],
          iconColor: Colors.teal.shade700,
          showLoading: _isProcessing,
        ),
        const SizedBox(height: 24),
        ElevatedButton.icon(
          onPressed: () => setState(() => _currentStep = 1),
          icon: const Icon(Icons.arrow_forward),
          label: const Text('Next Step'),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ],
    );
  }

  Widget _buildStep2Upload() {
    return Column(
      children: [
        const Text(
          'Step 2: Upload or Capture Image',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        const Text(
          'Upload a photo of your completed request slip or capture it directly with your camera.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
        const SizedBox(height: 32),
        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                icon: Icons.upload_file,
                title: 'Upload Image',
                subtitle: 'From gallery',
                onTap: () => _pickImage(ImageSource.gallery),
                gradientColors: [Colors.blue.shade50, Colors.blue.shade100],
                iconColor: Colors.blue.shade700,
                isCompleted: _uploadedImage != null,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildActionCard(
                icon: Icons.camera_alt,
                title: 'Take Photo',
                subtitle: 'Use camera',
                onTap: () => _pickImage(ImageSource.camera),
                gradientColors: [Colors.green.shade50, Colors.green.shade100],
                iconColor: Colors.green.shade700,
                isCompleted: _uploadedImage != null,
              ),
            ),
          ],
        ),
        if (_uploadedImage != null) ...[
          const SizedBox(height: 24),
          Container(
            height: 200,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              image: DecorationImage(
                image: FileImage(_uploadedImage!),
                fit: BoxFit.cover,
              ),
            ),
          ),
        ],
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => setState(() => _currentStep = 0),
                icon: const Icon(Icons.arrow_back),
                label: const Text('Previous'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _uploadedImage != null ? () => setState(() => _currentStep = 2) : null,
                icon: const Icon(Icons.arrow_forward),
                label: const Text('Next'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStep3Process() {
    return Column(
      children: [
        const Text(
          'Step 3: Process with OCR',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        const Text(
          'Extract information from your uploaded image using OCR technology.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
        const SizedBox(height: 32),
        _buildActionCard(
          icon: Icons.document_scanner,
          title: 'Process Image',
          subtitle: 'Extract data with OCR',
          onTap: _processImageWithOCR,
          gradientColors: [Colors.purple.shade50, Colors.purple.shade100],
          iconColor: Colors.purple.shade700,
          isCompleted: _extractedData.isNotEmpty,
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => setState(() => _currentStep = 1),
                icon: const Icon(Icons.arrow_back),
                label: const Text('Previous'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _extractedData.isNotEmpty ? () => setState(() => _currentStep = 3) : null,
                icon: const Icon(Icons.arrow_forward),
                label: const Text('Next'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStep4Review() {
    return Column(
      children: [
        const Text(
          'Step 4: Review & Edit Data',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        const Text(
          'Review the extracted information and make any necessary corrections.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
        const SizedBox(height: 32),
        Card(
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.info, color: Colors.blue),
                    const SizedBox(width: 8),
                    const Text(
                      'Extracted Information',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () {
                        _editExtractedData(_extractedData);
                      },
                      icon: const Icon(Icons.edit, color: Colors.blue),
                      tooltip: 'Edit Data',
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ..._extractedData.entries.map((entry) => _buildDataField(entry.key, entry.value)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => setState(() => _currentStep = 2),
                icon: const Icon(Icons.arrow_back),
                label: const Text('Previous'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _validateData(_extractedData) ? () => setState(() => _currentStep = 4) : null,
                icon: const Icon(Icons.arrow_forward),
                label: const Text('Next'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStep5Submit() {
    return Column(
      children: [
        const Text(
          'Step 5: Submit Request',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        const Text(
          'Review your final information and submit your Good Moral Certificate request.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
        const SizedBox(height: 32),
        Card(
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                const Icon(Icons.send, size: 48, color: Colors.purple),
                const SizedBox(height: 16),
                const Text(
                  'Ready to Submit',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'All information has been validated. Click submit to send your request.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 32),
        _buildActionCard(
          icon: Icons.send,
          title: 'Submit Request',
          subtitle: 'Send your application',
          onTap: _submitGoodMoralRequest,
          gradientColors: [Colors.purple.shade50, Colors.purple.shade100],
          iconColor: Colors.purple.shade700,
          showLoading: _isProcessing,
        ),
        const SizedBox(height: 24),
        OutlinedButton.icon(
          onPressed: () => setState(() => _currentStep = 3),
          icon: const Icon(Icons.arrow_back),
          label: const Text('Back to Review'),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ],
    );
  }

  Widget _buildApprovalStep(String title, int stepNumber, int currentStep, int approvalsReceived) {
    bool isCompleted = approvalsReceived >= stepNumber;
    bool isCurrent = currentStep == stepNumber && !isCompleted;

    return Column(
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isCompleted
                ? Colors.green
                : isCurrent
                    ? Colors.orange
                    : Colors.grey.shade300,
            border: Border.all(
              color: isCompleted
                  ? Colors.green.shade700
                  : isCurrent
                      ? Colors.orange.shade700
                      : Colors.grey.shade400,
              width: 2,
            ),
          ),
          child: Center(
            child: isCompleted
                ? const Icon(Icons.check, color: Colors.white, size: 24)
                : Text(
                    '$stepNumber',
                    style: TextStyle(
                      color: isCurrent ? Colors.white : Colors.grey.shade600,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: isCompleted
                ? Colors.green.shade800
                : isCurrent
                    ? Colors.orange.shade800
                    : Colors.grey.shade600,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildDataField(String key, String value) {
    final icons = {
      'name': Icons.person,
      'address': Icons.location_on,
      'course': Icons.school,
      'date': Icons.calendar_today,
      'purpose': Icons.description,
      'school_year': Icons.calendar_month,
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          Icon(icons[key] ?? Icons.info, color: Colors.grey.shade700, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  key.replaceAll('_', ' ').toUpperCase(),
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey.shade600),
                ),
                Text(value, style: const TextStyle(fontSize: 14)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDialogTitle(IconData icon, String title, MaterialColor color) {
    return Row(
      children: [
        Icon(icon, color: color.shade800, size: 28),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStepIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: List.generate(_steps.length, (index) {
          final isActive = index <= _currentStep;
          final isCompleted = index < _currentStep;

          return Expanded(
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isCompleted
                        ? Colors.green
                        : isActive
                            ? Colors.blue
                            : Colors.grey.shade300,
                  ),
                  child: Center(
                    child: isCompleted
                        ? const Icon(Icons.check, color: Colors.white, size: 16)
                        : Text(
                            '${index + 1}',
                            style: TextStyle(
                              color: isActive ? Colors.white : Colors.grey.shade600,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
                if (index < _steps.length - 1)
                  Expanded(
                    child: Container(
                      height: 2,
                      color: isCompleted ? Colors.green : Colors.grey.shade300,
                    ),
                  ),
              ],
            ),
          );
        }),
      ),
    );
  }

  // Dialog Methods
  void _showLoadingDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Row(
          children: [
            const CircularProgressIndicator(),
            const SizedBox(width: 16),
            Text(message),
          ],
        ),
      ),
    );
  }

  void _showSuccessDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: _buildDialogTitle(Icons.check_circle, title, Colors.green),
        content: Text(message, style: const TextStyle(fontSize: 16)),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.check, color: Colors.white),
              label: const Text('OK', style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade700,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showWarningDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: _buildDialogTitle(Icons.warning, title, Colors.amber),
        content: Text(message, style: const TextStyle(fontSize: 16)),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.check, color: Colors.white),
              label: const Text('OK', style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber.shade700,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: _buildDialogTitle(Icons.error, title, Colors.red),
        content: Text(message, style: const TextStyle(fontSize: 16)),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.close, color: Colors.white),
              label: const Text('Close', style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade700,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showExtractedDataDialog(Map<String, String> data) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: _buildDialogTitle(Icons.check_circle, 'Confirm Extracted Data', Colors.green),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Extracted Information:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              ...data.entries.map((entry) => _buildDataField(entry.key, entry.value)),
            ],
          ),
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(Icons.close, color: Colors.grey.shade700),
                    label: Text('Close', style: TextStyle(color: Colors.grey.shade700)),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Colors.grey.shade400),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context); // Close the extracted data dialog
                      _editExtractedData(data); // Open the edit dialog
                    },
                    icon: const Icon(Icons.edit, color: Colors.white),
                    label: const Text('Edit', style: TextStyle(color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade700,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }



  void _editExtractedData(Map<String, String> data) {
    // Removed Navigator.pop(context) to prevent navigation back to main panel
    final controllers = {
      'name': TextEditingController(text: data['name']),
      'address': TextEditingController(text: data['address']),
      'course': TextEditingController(text: data['course']),
      'date': TextEditingController(text: data['date']),
      'purpose': TextEditingController(text: data['purpose']),
      'school_year': TextEditingController(text: data['school_year']),
    };

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Extracted Data'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: controllers.entries
                .map((e) => _buildTextField(e.value, e.key, maxLines: e.key == 'purpose' ? 2 : 1))
                .toList(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final updatedData = {
                'name': controllers['name']!.text.trim(),
                'address': controllers['address']!.text.trim(),
                'course': controllers['course']!.text.trim(),
                'date': controllers['date']!.text.trim(),
                'purpose': controllers['purpose']!.text.trim(),
                'school_year': controllers['school_year']!.text.trim(),
              };
              
              setState(() => _extractedData = updatedData);
              _saveData(updatedData);
              Navigator.pop(context);
              _showSuccessDialog('Data Updated', 'The extracted data has been updated successfully.');
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final formSettingsProvider = Provider.of<FormSettingsProvider>(context);
    final formSettings = formSettingsProvider.formSettings;

    if (formSettings['good_moral_request_enabled'] != true) {
      return Scaffold(
        appBar: AppBar(
          title: Row(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Icon(Icons.verified_user, color: Colors.white, size: 28),
              SizedBox(width: 8),
              Text('Request of Good Moral', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ],
          ),
          backgroundColor: const Color.fromARGB(255, 30, 182, 88),
          elevation: 4,
        ),
        body: Container(
          height: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.lightGreen.withOpacity(0.3), Colors.green.shade900],
            ),
          ),
          child: Center(
            child: Text(
              'Good Moral Request is currently disabled by the administrator.',
              style: TextStyle(fontSize: 18, color: Colors.white),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    // Show current request status if exists
    if (_currentRequest != null && !_isCheckingStatus) {
      final status = _currentRequest!['approval_status'];
      final currentStep = _currentRequest!['current_approval_step'];
      final approvalsReceived = _currentRequest!['approvals_received'];

      return Scaffold(
        appBar: AppBar(
          title: Row(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Icon(Icons.verified_user, color: Colors.white, size: 28),
              SizedBox(width: 8),
              Text('Request of Good Moral', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ],
          ),
          backgroundColor: const Color.fromARGB(255, 30, 182, 88),
          elevation: 4,
        ),
        body: Container(
          height: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.lightGreen.withOpacity(0.3), Colors.green.shade900],
            ),
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                // Current Request Status
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Icon(
                        status == 'approved' ? Icons.check_circle :
                        status == 'rejected' ? Icons.cancel :
                        Icons.pending,
                        color: status == 'approved' ? Colors.green :
                               status == 'rejected' ? Colors.red :
                               Colors.orange,
                        size: 48,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        status == 'approved' ? 'Request Approved!' :
                        status == 'rejected' ? 'Request Rejected' :
                        'Request Under Review',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: status == 'approved' ? Colors.green.shade800 :
                                 status == 'rejected' ? Colors.red.shade800 :
                                 Colors.orange.shade800,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        status == 'approved' ?
                        'Your Good Moral Certificate request has been approved and is ready for download.' :
                        status == 'rejected' ?
                        'Your request has been rejected. Please contact your guidance counselor for more information.' :
                        'Your request is currently being reviewed by the approval committee.',
                        style: TextStyle(fontSize: 16, color: Colors.grey.shade700),
                        textAlign: TextAlign.center,
                      ),
                      if (status == 'pending') ...[
                        const SizedBox(height: 24),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.blue.shade200),
                          ),
                          child: Column(
                            children: [
                              const Text(
                                'Approval Progress',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                children: [
                                  _buildApprovalStep('Academic Head', 1, currentStep, approvalsReceived),
                                  _buildApprovalStep('Student Affairs', 2, currentStep, approvalsReceived),
                                  _buildApprovalStep('Administrative', 3, currentStep, approvalsReceived),
                                  _buildApprovalStep('Executive Head', 4, currentStep, approvalsReceived),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                      if (status == 'approved') ...[
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: () {
                            // TODO: Implement certificate download
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Certificate download will be implemented')),
                            );
                          },
                          icon: const Icon(Icons.download),
                          label: const Text('Download Certificate'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.verified_user, color: Colors.white, size: 28),
            SizedBox(width: 8),
            Text('Request of Good Moral', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ],
        ),
        backgroundColor: const Color.fromARGB(255, 30, 182, 88),
        elevation: 4,
      ),
      body: Container(
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.lightGreen.withOpacity(0.3), Colors.green.shade900],
          ),
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                // Step Indicator
                _buildStepIndicator(),
                const SizedBox(height: 32),

                // Step Content
                _buildStepContent(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}