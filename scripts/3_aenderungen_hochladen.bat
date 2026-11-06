@echo off
rem Branch anlegen, Commit, Push, Merge Request oeffnen - nie direkt auf main.
rem Die eigentliche Arbeit macht scripts\aenderungen-hochladen.ps1.
setlocal
cd /d "%~dp0.."
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0aenderungen-hochladen.ps1"
set RC=%errorlevel%
echo.
pause
endlocal & exit /b %RC%
