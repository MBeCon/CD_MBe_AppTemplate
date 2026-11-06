@echo off
rem Richtet .venv, Pakete, Pruefungen (pre-commit), .env und Tests ein.
rem Die eigentliche Arbeit macht scripts\setup-dev.ps1.
setlocal
cd /d "%~dp0.."
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0setup-dev.ps1"
set RC=%errorlevel%
echo.
pause
endlocal & exit /b %RC%
