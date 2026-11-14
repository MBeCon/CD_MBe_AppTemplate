@echo off
rem Legt aus der frisch geklonten Vorlage ein neues privates GitHub-Repository an (Organisation MBeCon).
rem Startet scripts/new-app.sh mit der Git Bash (Teil von Git fuer Windows).
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
"%GITBASH%" scripts/new-app.sh %*
:ende
echo.
pause
endlocal
