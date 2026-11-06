@echo off
rem Legt aus der frisch geklonten Vorlage ein neues GitLab-Projekt an.
rem Startet scripts/new-app.sh mit der Git Bash (Teil von Git fuer Windows).
setlocal
cd /d "%~dp0.."
set "GITBASH=%ProgramFiles%\Git\bin\bash.exe"
if not exist "%GITBASH%" set "GITBASH=%LOCALAPPDATA%\Programs\Git\bin\bash.exe"
if not exist "%GITBASH%" (
    echo FEHLER: Git Bash nicht gefunden. Git fuer Windows installieren: winget install --id Git.Git
    goto :ende
)
"%GITBASH%" scripts/new-app.sh %*
:ende
echo.
pause
endlocal
