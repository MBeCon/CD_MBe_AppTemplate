@echo off
rem Richtet die verbindliche QS auf GitHub ein (geschuetzter Branch main, Merge-Regeln).
rem Einmalig durch einen Admin des Repositorys, nachdem main einmal hochgeladen wurde.
rem Startet scripts/setup-github.sh mit der Git Bash (Teil von Git fuer Windows) -
rem nicht mit "bash" aus PowerShell, das waere WSL.
rem Voraussetzung: GitHub CLI angemeldet: gh auth login
setlocal
cd /d "%~dp0.."
set "GITBASH=%ProgramFiles%\Git\bin\bash.exe"
if not exist "%GITBASH%" set "GITBASH=%LOCALAPPDATA%\Programs\Git\bin\bash.exe"
if not exist "%GITBASH%" (
    echo FEHLER: Git Bash nicht gefunden. Git fuer Windows installieren: winget install --id Git.Git
    goto :ende
)
where gh >nul 2>nul
if errorlevel 1 (
    echo FEHLER: GitHub CLI ^(gh^) nicht gefunden. Installieren: winget install --id GitHub.cli
    echo Danach neues Terminal oeffnen und anmelden: gh auth login
    goto :ende
)
"%GITBASH%" scripts/setup-github.sh %*
:ende
echo.
pause
endlocal
