@echo off
rem Double-click to run the Python Dev setup on Windows.
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0setup.ps1" %*
echo.
pause
