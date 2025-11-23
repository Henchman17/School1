@echo off
echo ========================================
echo    NETWORK SETUP FOR FLUTTER EMULATOR
echo ========================================
echo.
echo This script will help you configure the network
echo settings for your Flutter app to connect to the backend.
echo.
echo Step 1: Finding your local IP address...
echo.
ipconfig | findstr /R /C:"IPv4 Address"
echo.
echo Step 2: Look for the IP address that starts with 192.168.x.x or 10.x.x.x
echo        This is your computer's local network IP address.
echo.
echo Step 3: Update lib/config.dart with this IP address
echo        Replace '192.168.1.10' with your actual IP address
echo.
echo Step 4: Make sure your emulator and computer are on the same Wi-Fi network
echo.
echo Step 5: Start the backend server with: dart run backend/server.dart
echo.
echo Step 6: Test the connection by running the Flutter app on emulator
echo.
pause
