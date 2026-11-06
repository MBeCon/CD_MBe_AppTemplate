# Richtet die Entwicklungsumgebung unter Windows ein (aufgerufen von 2_umgebung_einrichten.bat).
# Schritte: Python-Version prüfen, .venv anlegen, Pakete installieren, pre-commit-Hooks,
# .env aus .env.example erzeugen (mit zufälligem SECRET_KEY), Tests ausführen.
# Alle Werkzeuge werden mit "python -m ..." aufgerufen (keine .exe aus der .venv nötig).

$ErrorActionPreference = "Continue"  # Fehler werden über $LASTEXITCODE geprüft
Set-Location (Split-Path -Parent $PSScriptRoot)

function Schritt($text) { Write-Host ""; Write-Host "==> $text" -ForegroundColor Magenta }
function Abbruch($text) { Write-Host ""; Write-Host "FEHLER: $text" -ForegroundColor Red; exit 1 }

$version = (Get-Content .python-version -TotalCount 1).Trim()

Schritt "Python $version suchen"
$py = $null
try { & py "-$version" --version *> $null; if ($LASTEXITCODE -eq 0) { $py = @("py", "-$version") } } catch { }
if (-not $py) { Abbruch "Python $version wurde nicht gefunden. Zuerst scripts\1_python_installieren.bat ausführen, VS Code neu starten." }
& $py[0] $py[1] --version

$venvPy = ".venv\Scripts\python.exe"
if (Test-Path $venvPy) {
    $vorhanden = (& $venvPy -c "import sys; print(f'{sys.version_info[0]}.{sys.version_info[1]}')").Trim()
    if ($vorhanden -ne $version) {
        Abbruch ".venv nutzt eine andere Python-Version ($vorhanden statt $version). Ordner .venv im Explorer löschen und dieses Skript erneut starten."
    }
    Schritt ".venv vorhanden (Python $vorhanden)"
} else {
    Schritt ".venv anlegen"
    & $py[0] $py[1] -m venv .venv
    if ($LASTEXITCODE -ne 0) { Abbruch ".venv konnte nicht angelegt werden." }
}

Schritt "Pakete installieren (requirements-dev.txt)"
& $venvPy -m pip install --upgrade --quiet pip
& $venvPy -m pip install --quiet -r requirements-dev.txt
if ($LASTEXITCODE -ne 0) { Abbruch "Pakete konnten nicht installiert werden (Netzwerk/Proxy prüfen)." }

Schritt "Prüfungen vor Commit und Push einrichten (pre-commit)"
& $venvPy -m pre_commit install
if ($LASTEXITCODE -ne 0) { Abbruch "pre-commit konnte nicht eingerichtet werden. Ist das ein Git-Repository?" }

Schritt "Lokale Einstellungen (.env)"
if (Test-Path .env) {
    Write-Host "    .env existiert bereits - bleibt unverändert."
} else {
    $key = (& $venvPy -c "import secrets; print(secrets.token_hex(32))").Trim()
    $inhalt = (Get-Content .env.example -Raw -Encoding UTF8) -replace "(?m)^SECRET_KEY=.*$", "SECRET_KEY=$key"
    [System.IO.File]::WriteAllText((Join-Path (Get-Location) ".env"), $inhalt, (New-Object System.Text.UTF8Encoding $false))
    Write-Host "    .env aus .env.example erzeugt, SECRET_KEY zufällig gesetzt."
}

Schritt "PowerShell-Skripte im eigenen Benutzer erlauben (für die Anzeige (.venv) im Terminal)"
# Wirksame Richtlinie ohne den Prozess-Bereich (dieses Skript läuft selbst mit "Bypass")
$policy = (Get-ExecutionPolicy -List | Where-Object { $_.Scope -ne "Process" -and $_.ExecutionPolicy -ne "Undefined" } |
    Select-Object -First 1).ExecutionPolicy
if (-not $policy) { $policy = "Restricted" }
if ("$policy" -in @("Restricted", "AllSigned")) {
    try {
        Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned -Force -ErrorAction Stop
        Write-Host "    ExecutionPolicy für den eigenen Benutzer auf RemoteSigned gesetzt."
    } catch {
        Write-Host "    Hinweis: ExecutionPolicy ist per Richtlinie festgelegt ($policy). Die .venv wird dann" -ForegroundColor Yellow
        Write-Host "    nicht automatisch aktiviert - Befehle trotzdem mit .venv\Scripts\python -m ... ausführen." -ForegroundColor Yellow
    }
} else {
    Write-Host "    ExecutionPolicy: $policy - passt."
}

Schritt "Tests ausführen"
& $venvPy -m pytest -q
if ($LASTEXITCODE -ne 0) { Abbruch "Tests sind fehlgeschlagen. Meldung oben lesen." }

Write-Host ""
Write-Host "Fertig. Jetzt dieses Terminal schließen und ein neues öffnen: vorne steht (.venv)." -ForegroundColor Green
