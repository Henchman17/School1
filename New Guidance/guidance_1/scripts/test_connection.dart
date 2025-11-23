import 'dart:io';
import 'package:http/http.dart' as http;

void main() async {
  print('🔍 Testing connection to backend server...');

  // Get local IP
  final interfaces = await NetworkInterface.list();
  String? localIP;

  for (var interface in interfaces) {
    for (var addr in interface.addresses) {
      if (addr.type == InternetAddressType.IPv4 &&
          !addr.address.startsWith('127.') &&
          !addr.address.startsWith('169.254.')) {
        localIP = addr.address;
        break;
      }
    }
    if (localIP != null) break;
  }

  if (localIP == null) {
    print('❌ Could not find local IP address');
    return;
  }

  print('📡 Your local IP: $localIP');

  // Test localhost
  print('\n🧪 Testing localhost:8080...');
  try {
    final response = await http.get(Uri.parse('http://localhost:8080/api/courses'))
        .timeout(const Duration(seconds: 5));
    if (response.statusCode == 200) {
      print('✅ Localhost connection successful!');
    } else {
      print('⚠️  Localhost responded with status: ${response.statusCode}');
    }
  } catch (e) {
    print('❌ Localhost connection failed: $e');
  }

  // Test local network IP
  print('\n🧪 Testing $localIP:8080...');
  try {
    final response = await http.get(Uri.parse('http://$localIP:8080/api/courses'))
        .timeout(const Duration(seconds: 5));
    if (response.statusCode == 200) {
      print('✅ Network IP connection successful!');
      print('🎉 Update lib/config.dart to use: http://$localIP:8080');
    } else {
      print('⚠️  Network IP responded with status: ${response.statusCode}');
    }
  } catch (e) {
    print('❌ Network IP connection failed: $e');
    print('💡 Make sure the backend server is running: dart run backend/server.dart');
  }

  print('\n📝 Next steps:');
  print('1. If network IP test failed, start the backend server');
  print('2. Update lib/config.dart with your IP: $localIP');
  print('3. Run the Flutter app on emulator');
}
