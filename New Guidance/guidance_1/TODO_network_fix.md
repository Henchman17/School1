# Network Configuration Fix for Mobile Devices

## Problem
The Flutter app was unable to connect to the backend server when running on physical mobile devices because it was using `localhost:8080`, which mobile devices cannot access. The server runs on the computer's local network IP, but the app config only handled Android emulators with `10.0.2.2`.

## Solution
Updated `lib/config.dart` to dynamically detect the local network IP address for mobile devices (Android and iOS) using `NetworkInterface.list()`. This allows physical devices to connect to the server via the computer's local IP (e.g., 192.168.x.x:8080).

### Changes Made
1. **lib/config.dart**: Changed `apiBaseUrl` to an async getter that fetches the local IP for mobile platforms.
2. **lib/login_page.dart**: Updated `_login()` and `_register()` to await `AppConfig.apiBaseUrl`.
3. **lib/student/guidance_scheduling_page.dart**: Updated all API calls to await `AppConfig.apiBaseUrl`.

### How It Works
- For Android/iOS: Attempts to find the WiFi/Ethernet interface IP address and uses `http://{local_ip}:8080`.
- Fallback for Android: If network interface fails, uses `http://10.0.2.2:8080` (emulator).
- For other platforms (web/desktop): Uses `http://localhost:8080`.

### Testing
- Ensure the backend server is running on the computer.
- Connect mobile device and computer to the same WiFi network.
- Run the Flutter app on the physical device.
- The app should now connect to the server using the local IP.

### Notes
- The server must be bound to `0.0.0.0` (which it is) to accept connections from the local network.
- Firewall settings may need to allow incoming connections on port 8080.
- For iOS devices, ensure the app has network permissions (added automatically by Flutter).
