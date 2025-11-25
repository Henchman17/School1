import 'dart:io';

class AppConfig {
  // MANUAL IP SETTING: Set this to your IPv4 address for manual override
  // Example: '192.168.1.100' or '10.0.2.2' for Android emulator
  // Leave as null to use automatic detection
  static const String? MANUAL_IP = '192.168.1.4'; // Change this to your IP

  // OCR.space API Configuration
  static const String OCR_API_KEY = "K83005968488957";
  static const String OCR_API_URL = "https://api.ocr.space/parse/image";

  static Future<String> get apiBaseUrl async {
    // Use manual IP if set
    if (MANUAL_IP != null) {
      return 'http://$MANUAL_IP:8080';
    }

    // Automatic IP detection
    try {
      final interfaces = await NetworkInterface.list();

      for (var interface in interfaces) {
        for (var addr in interface.addresses) {
          if (addr.type == InternetAddressType.IPv4 &&
              !addr.address.startsWith('127.') &&
              !addr.address.startsWith('169.254.')) {
            return 'http://${addr.address}:8080';
          }
        }
      }

      return 'http://localhost:8080';
    } catch (e) {
      return 'http://localhost:8080';
    }
  }
}
