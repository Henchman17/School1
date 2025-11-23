@echo off
echo Setting up ADB port forwarding...
adb reverse tcp:8080 tcp:8080
echo Port forwarding set up successfully!
pause
