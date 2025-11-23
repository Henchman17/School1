import 'dart:io';

class AppConfig {
  // MANUAL IP SETTING: Set this to your IPv4 address for manual override
  // Example: '192.168.1.100' or '10.0.2.2' for Android emulator
  // Leave as null to use automatic detection
  static const String? MANUAL_IP = '192.168.1.8'; // Change this to your IP

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
