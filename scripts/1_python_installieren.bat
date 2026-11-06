@echo off
rem Installiert die Python-Version aus .python-version fuer den eigenen Benutzer (winget).
rem Einmal pro Rechner bzw. wenn sich .python-version aendert.
setlocal
cd /d "%~dp0.."
set /p PYVER=<.python-version
for /f "tokens=* delims= " %%a in ("%PYVER%") do set PYVER=%%a

echo ==^> Benoetigt wird Python %PYVER%
py -%PYVER% --version >nul 2>&1
if %errorlevel%==0 (
    py -%PYVER% --version
    echo Python %PYVER% ist bereits installiert - nichts zu tun.
    goto :ende
)

where winget >nul 2>&1
if errorlevel 1 (
    echo FEHLER: winget fehlt. Python %PYVER% bitte ueber das Softwareportal bzw. die IT installieren.
    goto :ende
)

echo ==^> Installiere Python %PYVER% ...
winget install --exact --id Python.Python.%PYVER% --scope user --accept-package-agreements --accept-source-agreements
if errorlevel 1 (
    echo FEHLER: Installation fehlgeschlagen. Bitte die IT kontaktieren.
    goto :ende
)
echo.
echo Fertig. Jetzt VS Code komplett schliessen und neu oeffnen, dann:
echo     scripts\2_umgebung_einrichten.bat

:ende
echo.
pause
endlocal
