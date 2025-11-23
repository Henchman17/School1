@echo off
echo Adding Firewall Rules for Guidance App Server...

REM Add inbound rule for TCP port 8080
netsh advfirewall firewall add rule ^
    name="Guidance App Server" ^
    dir=in ^
    action=allow ^
    protocol=TCP ^
    localport=8080

REM Add outbound rule for TCP port 8080
netsh advfirewall firewall add rule ^
    name="Guidance App Server" ^
    dir=out ^
    action=allow ^
    protocol=TCP ^
    localport=8080

echo Firewall rules added successfully!
pause
