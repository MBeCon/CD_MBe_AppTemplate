# Lädt Änderungen sicher auf GitLab hoch (aufgerufen von 3_aenderungen_hochladen.bat):
# eigener Branch statt main, Dateiliste bestätigen, Commit (mit pre-commit-Prüfungen),
# Push (mit Tests), danach optional den Merge Request im Browser öffnen.

$ErrorActionPreference = "Continue"  # Fehler werden über $LASTEXITCODE geprüft
Set-Location (Split-Path -Parent $PSScriptRoot)

function Abbruch($text) { Write-Host ""; Write-Host $text -ForegroundColor Red; exit 1 }
function Frage($text) { return ((Read-Host "$text [J/N]").Trim().ToUpper() -in @("J", "Y")) }

# Werkzeuge aus der .venv verwenden (pre-commit, Tests vor dem Push)
if (-not (Test-Path ".venv\Scripts\python.exe")) { Abbruch "Keine .venv gefunden. Zuerst scripts\2_umgebung_einrichten.bat ausführen." }
$env:Path = "$(Resolve-Path .venv\Scripts);$env:Path"

git rev-parse --is-inside-work-tree *> $null
if ($LASTEXITCODE -ne 0) { Abbruch "Dieser Ordner ist kein Git-Repository." }

$branch = (git branch --show-current).Trim()
$aenderungen = git status --short

# --- a) Branch ------------------------------------------------------------------
if ($branch -in @("main", "master")) {
    if (-not $aenderungen) { Abbruch "Keine Änderungen vorhanden - nichts hochzuladen." }
    Write-Host "Du bist auf '$branch'. Für die Änderungen wird ein neuer Branch angelegt."
    $art = Read-Host "Art der Änderung: 1 = feature (neu/erweitert), 2 = fix (Fehlerbehebung)"
    $prefix = if ($art.Trim() -eq "2") { "fix" } else { "feature" }
    $name = Read-Host "Kurzer Name, z. B. projekt-einrichten"
    $name = $name.Trim().ToLower() -replace "ä", "ae" -replace "ö", "oe" -replace "ü", "ue" -replace "ß", "ss"
    $name = ($name -replace "[^a-z0-9]+", "-").Trim("-")
    if (-not $name) { Abbruch "Kein gültiger Name angegeben." }
    $branch = "$prefix/$name"
    git switch -c $branch
    if ($LASTEXITCODE -ne 0) { Abbruch "Branch '$branch' konnte nicht angelegt werden (existiert er schon?)." }
} else {
    Write-Host "Aktueller Branch: $branch"
}

# --- b) Dateiliste + c) Commit ---------------------------------------------------
if ($aenderungen) {
    Write-Host ""
    Write-Host "Diese Dateien werden übernommen:" -ForegroundColor Magenta
    git status --short
    Write-Host ""
    if (-not (Frage "Stimmt die Liste?")) { Abbruch "Abgebrochen - nichts geändert. Unerwünschte Dateien prüfen (.gitignore)." }

    $nachricht = ""
    while (-not $nachricht.Trim()) { $nachricht = Read-Host "Kurze Beschreibung, z. B. Projekt Lagerliste eingerichtet" }

    git add -A
    Write-Host "Prüfungen laufen (ruff, gitleaks, bandit ...) ..." -ForegroundColor Magenta
    git commit -m $nachricht
    if ($LASTEXITCODE -ne 0) {
        Abbruch "Der Commit wurde NICHT erstellt. Prüfungen haben Dateien korrigiert oder Fehler gefunden.`nMeldung oben lesen, ggf. beheben und Skript 3 erneut starten."
    }
}

# --- Push ------------------------------------------------------------------------
Write-Host ""
Write-Host "Hochladen nach GitLab (vorher laufen alle Tests) ..." -ForegroundColor Magenta
git push -u origin $branch
if ($LASTEXITCODE -ne 0) {
    Abbruch "Push fehlgeschlagen. Tests rot? Meldung oben lesen.`nAnmeldung: glab auth login --hostname gitlab.technosert.com"
}

# --- d) Merge Request ------------------------------------------------------------
$remote = (git remote get-url origin).Trim()
if ($remote -match "^git@([^:]+):(.+?)(\.git)?$") { $basis = "https://$($Matches[1])/$($Matches[2])" }
else { $basis = $remote -replace "\.git$", "" -replace "//[^@/]+@", "//" }
$url = "$basis/-/merge_requests/new?merge_request%5Bsource_branch%5D=$([uri]::EscapeDataString($branch))&merge_request%5Btarget_branch%5D=main"

Write-Host ""
Write-Host "Hochgeladen auf Branch $branch." -ForegroundColor Green
if (Frage "Merge Request jetzt im Browser öffnen?") { Start-Process $url } else { Write-Host "Später: $url" }
