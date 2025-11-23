import 'dart:io';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:flutter_tesseract_ocr/flutter_tesseract_ocr.dart';
import 'dart:ui' as ui;

class OcrProcessor {
  static Future<Map<String, String>> processImage(File imageFile) async {
    try {
      Map<String, String> extractedData = {};

      if (Platform.isAndroid || Platform.isIOS) {
        // Use Google ML Kit for mobile platforms
        extractedData = await _processWithGoogleMLKit(imageFile);
      } else {
        // Use Tesseract for desktop platforms
        extractedData = await _processWithTesseract(imageFile);
      }

      // Structure and clean the extracted data
      return _structureExtractedData(extractedData);
    } catch (e) {
      print('Error processing OCR: $e');
      return {};
    }
  }

  static Future<Map<String, String>> processIdDocument(File imageFile, String idType) async {
    try {
      Map<String, String> extractedData = {};

      if (Platform.isAndroid || Platform.isIOS) {
        // Use Google ML Kit for mobile platforms
        extractedData = await _processWithGoogleMLKit(imageFile);
      } else {
        // Use Tesseract for desktop platforms
        extractedData = await _processWithTesseract(imageFile);
      }

      // Structure and clean the extracted data for ID documents
      return _structureExtractedIdData(extractedData, idType);
    } catch (e) {
      print('Error processing ID document: $e');
      return {};
    }
  }

  static Future<Map<String, String>> _processWithGoogleMLKit(File imageFile) async {
    final textRecognizer = TextRecognizer();
    final inputImage = InputImage.fromFile(imageFile);

    try {
      final RecognizedText recognizedText = await textRecognizer.processImage(inputImage);
      await textRecognizer.close();

      return _parseRecognizedText(recognizedText.text);
    } catch (e) {
      await textRecognizer.close();
      rethrow;
    }
  }

  static Future<Map<String, String>> _processWithTesseract(File imageFile) async {
    try {
      final String recognizedText = await FlutterTesseractOcr.extractText(
        imageFile.path,
        language: 'eng',
        args: {
          "psm": "6",
          "oem": "3",
        },
      );

      return _parseRecognizedText(recognizedText);
    } catch (e) {
      print('Tesseract OCR error: $e');
      return {};
    }
  }

  static Map<String, String> _parseRecognizedText(String text) {
    final Map<String, String> data = {};
    final lines = text.split('\n').map((line) => line.trim()).where((line) => line.isNotEmpty).toList();

    // First pass: Look for structured patterns (key: value)
    for (final line in lines) {
      final colonIndex = line.indexOf(':');
      if (colonIndex != -1) {
        final key = line.substring(0, colonIndex).trim().toLowerCase();
        final value = line.substring(colonIndex + 1).trim();

        if (_isNameKey(key)) {
          data['name'] = _cleanValue(value);
        } else if (_isIdKey(key)) {
          data['student_id'] = _cleanValue(value);
        } else if (_isCourseKey(key)) {
          data['course'] = _cleanValue(value);
        } else if (_isYearKey(key)) {
          data['year_level'] = _cleanValue(value);
        } else if (_isPurposeKey(key)) {
          data['purpose'] = _cleanValue(value);
        }
      }
    }

    // Second pass: Fallback parsing for unstructured text
    if (data.isEmpty || data.length < 3) {
      data.addAll(_fallbackParsing(lines));
    }

    // Third pass: Regex-based extraction for specific patterns
    data.addAll(_regexExtraction(text));

    // Validate and clean data
    return _validateAndCleanData(data);
  }

  static bool _isNameKey(String key) {
    final nameKeywords = ['name', 'student name', 'full name', 'studentname', 'fullname'];
    return nameKeywords.any((keyword) => key.contains(keyword));
  }

  static bool _isIdKey(String key) {
    final idKeywords = ['id', 'student id', 'student number', 'studentid', 'studentnumber', 'identification'];
    return idKeywords.any((keyword) => key.contains(keyword));
  }

  static bool _isCourseKey(String key) {
    final courseKeywords = ['course', 'program', 'major', 'degree', 'field of study'];
    return courseKeywords.any((keyword) => key.contains(keyword));
  }

  static bool _isYearKey(String key) {
    final yearKeywords = ['year', 'level', 'grade', 'class', 'year level', 'academic year'];
    return yearKeywords.any((keyword) => key.contains(keyword));
  }

  static bool _isPurposeKey(String key) {
    final purposeKeywords = ['purpose', 'reason', 'request for', 'application for'];
    return purposeKeywords.any((keyword) => key.contains(keyword));
  }

  static String _cleanValue(String value) {
    // Remove extra whitespace and normalize
    return value.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  static Map<String, String> _fallbackParsing(List<String> lines) {
    final Map<String, String> data = {};

    // Look for patterns without colons
    for (final line in lines) {
      final lowerLine = line.toLowerCase();

      // Check for name patterns (usually title case or all caps)
      if (_isLikelyName(line) && !data.containsKey('name')) {
        data['name'] = _cleanValue(line);
      }

      // Check for ID patterns (numbers, alphanumeric with specific formats)
      if (_isLikelyId(line) && !data.containsKey('student_id')) {
        data['student_id'] = _cleanValue(line);
      }

      // Check for course patterns
      if (_isLikelyCourse(line) && !data.containsKey('course')) {
        data['course'] = _cleanValue(line);
      }
    }

    return data;
  }

  static Map<String, String> _regexExtraction(String text) {
    final Map<String, String> data = {};

    // Student ID patterns (various formats)
    final idPatterns = [
      RegExp(r'\b\d{2}-\d{4}-\d{3}\b'), // 12-3456-789
      RegExp(r'\b\d{9}\b'), // 9 digits
      RegExp(r'\b\d{8}\b'), // 8 digits
      RegExp(r'\b[A-Z]{2,3}\d{6,8}\b'), // ABC123456
    ];

    for (final pattern in idPatterns) {
      final match = pattern.firstMatch(text);
      if (match != null && !data.containsKey('student_id')) {
        data['student_id'] = match.group(0)!;
        break;
      }
    }

    // Year level patterns
    final yearPatterns = [
      RegExp(r'\b(?:1st|2nd|3rd|4th|5th)\s*(?:year|yr|level)\b', caseSensitive: false),
      RegExp(r'\b(?:year|yr|level)\s*(?:1|2|3|4|5)\b', caseSensitive: false),
    ];

    for (final pattern in yearPatterns) {
      final match = pattern.firstMatch(text);
      if (match != null && !data.containsKey('year_level')) {
        data['year_level'] = match.group(0)!;
        break;
      }
    }

    return data;
  }

  static Map<String, String> _validateAndCleanData(Map<String, String> data) {
    final Map<String, String> validatedData = {};

    data.forEach((key, value) {
      final cleanedValue = _cleanValue(value);
      if (cleanedValue.isNotEmpty && cleanedValue.length > 1) {
        // Additional validation based on field type
        if (key == 'student_id' && _isValidStudentId(cleanedValue)) {
          validatedData[key] = cleanedValue;
        } else if (key == 'name' && _isValidName(cleanedValue)) {
          validatedData[key] = cleanedValue;
        } else if (key == 'course' && cleanedValue.length > 2) {
          validatedData[key] = cleanedValue;
        } else if (key == 'year_level' && cleanedValue.length > 1) {
          validatedData[key] = cleanedValue;
        } else if (key == 'purpose' && cleanedValue.length > 2) {
          validatedData[key] = cleanedValue;
        }
      }
    });

    return validatedData;
  }

  static bool _isLikelyName(String text) {
    // Names typically have title case or are all caps, contain spaces, no numbers
    if (RegExp(r'\d').hasMatch(text)) return false;
    if (text.length < 3 || text.length > 50) return false;

    final words = text.split(' ');
    if (words.length < 2) return false;

    // Check if most words start with capital letters
    int capitalizedWords = 0;
    for (final word in words) {
      if (word.isNotEmpty && RegExp(r'^[A-Z]').hasMatch(word)) {
        capitalizedWords++;
      }
    }

    return capitalizedWords >= words.length * 0.5;
  }

  static bool _isLikelyId(String text) {
    // IDs typically contain numbers, may have dashes or letters
    if (text.length < 5 || text.length > 15) return false;

    // Contains numbers
    if (!RegExp(r'\d').hasMatch(text)) return false;

    // Not too many spaces
    if (text.split(' ').length > 3) return false;

    return true;
  }

  static bool _isLikelyCourse(String text) {
    // Courses typically contain "Bachelor", "Master", "Engineering", "Science", etc.
    final courseIndicators = [
      'bachelor', 'master', 'engineering', 'science', 'technology',
      'business', 'arts', 'education', 'medicine', 'law'
    ];

    final lowerText = text.toLowerCase();
    return courseIndicators.any((indicator) => lowerText.contains(indicator));
  }

  static bool _isValidStudentId(String id) {
    // Basic validation for student ID format
    if (id.length < 5 || id.length > 15) return false;

    // Must contain at least some numbers
    if (!RegExp(r'\d').hasMatch(id)) return false;

    // Should not contain too many special characters
    final specialChars = RegExp(r'[^\w\s-]').allMatches(id);
    if (specialChars.length > 2) return false;

    return true;
  }

  static bool _isValidName(String name) {
    // Basic validation for names
    if (name.length < 3 || name.length > 50) return false;

    // Should not contain numbers or too many special characters
    if (RegExp(r'\d').hasMatch(name)) return false;
    if (RegExp(r'[^\w\s]').allMatches(name).length > 2) return false;

    // Should have at least two words (first and last name)
    final words = name.split(' ').where((w) => w.isNotEmpty).length;
    if (words < 2) return false;

    return true;
  }

  static bool _containsKeywords(String text, List<String> keywords) {
    final lowerText = text.toLowerCase();
    return keywords.any((keyword) => lowerText.contains(keyword.toLowerCase()));
  }

  static String _extractValue(String line) {
    // Try to extract value after colon or common separators
    final colonIndex = line.indexOf(':');
    if (colonIndex != -1 && colonIndex < line.length - 1) {
      return line.substring(colonIndex + 1).trim();
    }

    // Try to extract after common patterns
    final patterns = [' - ', ' : ', ' – '];
    for (final pattern in patterns) {
      final index = line.indexOf(pattern);
      if (index != -1 && index < line.length - pattern.length) {
        return line.substring(index + pattern.length).trim();
      }
    }

    return line.trim();
  }

  static Map<String, String> _structureExtractedData(Map<String, String> rawData) {
    final Map<String, String> structuredData = {};

    // Clean and validate extracted data
    rawData.forEach((key, value) {
      if (value.isNotEmpty) {
        // Remove extra whitespace and special characters
        final cleanedValue = value.replaceAll(RegExp(r'[^\w\s\-\.]'), '').trim();
        if (cleanedValue.isNotEmpty) {
          structuredData[key] = cleanedValue;
        }
      }
    });

    return structuredData;
  }

  static Map<String, String> _structureExtractedIdData(Map<String, String> rawData, String idType) {
    final Map<String, String> structuredData = {};

    // Clean and validate extracted data for ID documents
    rawData.forEach((key, value) {
      if (value.isNotEmpty) {
        // Remove extra whitespace and special characters
        final cleanedValue = value.replaceAll(RegExp(r'[^\w\s\-\.]'), '').trim();
        if (cleanedValue.isNotEmpty) {
          structuredData[key] = cleanedValue;
        }
      }
    });

    // Enhanced ID document processing for better name, address, and signature extraction
    // Focus on common ID document patterns (Driver's License, Student ID, etc.)

    // Extract name with enhanced patterns
    if (!structuredData.containsKey('name') || structuredData['name']!.length < 3) {
      final namePatterns = [
        RegExp(r'(?:NAME|Name|name)[\s:]*([A-Z\s]+)', caseSensitive: false),
        RegExp(r'(?:FULL\s*NAME|Full\s*Name)[\s:]*([A-Z\s]+)', caseSensitive: false),
        RegExp(r'(?:STUDENT\s*NAME|Student\s*Name)[\s:]*([A-Z\s]+)', caseSensitive: false),
        // Look for title case names (First Last format)
        RegExp(r'\b([A-Z][a-z]+\s+[A-Z][a-z]+)\b'),
        // Look for all caps names
        RegExp(r'\b([A-Z]{2,}\s+[A-Z]{2,})\b'),
      ];

      for (final pattern in namePatterns) {
        final match = pattern.firstMatch(rawData.values.join(' '));
        if (match != null && match.group(1) != null) {
          final extractedName = match.group(1)!.trim();
          if (extractedName.length >= 3 && extractedName.length <= 50) {
            structuredData['name'] = extractedName;
            break;
          }
        }
      }
    }

    // Extract address with enhanced patterns
    if (!structuredData.containsKey('address')) {
      final addressPatterns = [
        RegExp(r'(?:ADDRESS|Address|address)[\s:]*([^\n\r]{10,100})', caseSensitive: false),
        RegExp(r'(?:HOME|Home|home)[\s:]*([^\n\r]{10,100})', caseSensitive: false),
        RegExp(r'(?:LOCATION|Location|location)[\s:]*([^\n\r]{10,100})', caseSensitive: false),
        // Look for address-like patterns (contains numbers and street names)
        RegExp(r'\b(\d+\s+[A-Za-z0-9\s,.-]{10,80})\b'),
      ];

      for (final pattern in addressPatterns) {
        final match = pattern.firstMatch(rawData.values.join(' '));
        if (match != null && match.group(1) != null) {
          final extractedAddress = match.group(1)!.trim();
          if (extractedAddress.length >= 10 && extractedAddress.length <= 100) {
            structuredData['address'] = extractedAddress;
            break;
          }
        }
      }
    }

    // Extract signature (usually at bottom of document)
    if (!structuredData.containsKey('signature')) {
      // Look for signature patterns or assume last extracted text might be signature
      final allText = rawData.values.join(' ').toLowerCase();
      if (allText.contains('signature') || allText.contains('signed')) {
        // If signature is mentioned, look for the text after it
        final signatureMatch = RegExp(r'(?:signature|signed)[\s:]*([^\n\r]{3,30})', caseSensitive: false)
            .firstMatch(rawData.values.join(' '));
        if (signatureMatch != null && signatureMatch.group(1) != null) {
          structuredData['signature'] = signatureMatch.group(1)!.trim();
        }
      }
    }

    return structuredData;
  }

  static Future<bool> isImageValid(File imageFile) async {
    try {
      final bytes = await imageFile.readAsBytes();
      // Check if file size is reasonable (not too small or too large)
      if (bytes.length < 1000) return false; // Too small
      if (bytes.length > 50 * 1024 * 1024) return false; // Too large (>50MB)

      // Try to decode as image
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      frame.image.dispose();

      return true;
    } catch (e) {
      return false;
    }
  }
}
