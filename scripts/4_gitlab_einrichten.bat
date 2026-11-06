@echo off
rem Richtet die verbindliche QS auf GitLab ein (geschuetzter Branch, Merge-Regeln).
rem Einmalig durch einen Maintainer, nachdem die Pipeline einmal gelaufen ist.
rem Startet scripts/setup-gitlab.sh mit der Git Bash (Teil von Git fuer Windows) -
rem nicht mit "bash" aus PowerShell, das waere WSL.
rem Voraussetzung: GitLab CLI angemeldet: glab auth login --hostname gitlab.technosert.com
setlocal
cd /d "%~dp0.."
set "GITBASH=%ProgramFiles%\Git\bin\bash.exe"
if not exist "%GITBASH%" set "GITBASH=%LOCALAPPDATA%\Programs\Git\bin\bash.exe"
if not exist "%GITBASH%" (
    echo FEHLER: Git Bash nicht gefunden. Git fuer Windows installieren: winget install --id Git.Git
    goto :ende
)
where glab >nul 2>nul
if errorlevel 1 (
    echo FEHLER: GitLab CLI ^(glab^) nicht gefunden. Installieren: winget install --id GLab.GLab
    echo Danach neues Terminal oeffnen und anmelden: glab auth login --hostname gitlab.technosert.com
    goto :ende
)
"%GITBASH%" scripts/setup-gitlab.sh %*
:ende
echo.
pause
endlocal
