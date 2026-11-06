# CLAUDE.md – Regeln für dieses Repository

Interne te-Anwendung aus dem Citizen Development. Sie wird ausschließlich im Unternehmen
genutzt, läuft als Docker-Container und wird über die GitLab-Pipeline deployed.
Diese Regeln sind verbindlich. Wenn eine Anforderung einer Regel widerspricht: nachfragen,
nicht stillschweigend abweichen.

## Stack

- Python 3.13, Flask (Application Factory in `app/__init__.py`), Jinja2-Templates in `app/templates/`
- gunicorn im Container, Konfiguration nur über Umgebungsvariablen (`.env.example`)
- Tests mit pytest in `tests/`, Lint/Format mit ruff, Security mit bandit und pip-audit
- UI: technosert-App-Design – `app/static/css/style.css`, Logo `app/static/images/technosert_logo_white.png`,
  Grundlayout in `app/templates/base.html`. Nur ergänzen, nichts umdefinieren.
- JavaScript nur als Datei in `app/static/js/` (die Content-Security-Policy verbietet Inline-Skripte und `onclick=`).

## Befehle

Windows (VS-Code-Terminal, PowerShell) – einmal pro Rechner bzw. Klon:

```bash
scripts\1_python_installieren.bat     # Python-Version aus .python-version (3.13) installieren
scripts\2_umgebung_einrichten.bat     # .venv, Pakete, pre-commit, .env, Tests
scripts\3_aenderungen_hochladen.bat   # Branch, Commit, Push, Merge Request – nie auf main
scripts\4_gitlab_einrichten.bat      # einmalig (Maintainer): geschützter Branch, Merge-Regeln
```

Werkzeuge immer mit `python -m` aufrufen (funktioniert auch, wenn .exe-Dateien in der .venv gesperrt sind):

```bash
python -m flask --app wsgi run --debug    # lokal starten (benötigt .env)
python -m pytest                          # Tests inkl. Coverage-Grenze
python -m pre_commit run --all-files      # alle lokalen QS-Checks
python -m pip_audit -r requirements.txt   # Abhängigkeiten auf Schwachstellen prüfen
docker compose up --build                 # Container lokal testen
```

macOS/Linux: `bash scripts/setup-dev.sh`, danach `source .venv/bin/activate`.

## Arbeitsweise (Git)

- Nie direkt auf `main` arbeiten. Für jede Änderung einen Branch `feature/…` oder `fix/…` anlegen.
- Kleine, nachvollziehbare Commits mit aussagekräftiger Nachricht.
- Änderungen kommen nur über Merge Request nach `main`. Ein anderer Entwickler reviewt.
- Vor jedem Merge Request den Skill `te-cd-qs-review` aus dem Plugin `te-cd-qs` ausführen
  (`/te-cd-qs:te-cd-qs-review`). Bei Urteil ❌
  wird kein MR erstellt.

## Verbindliche Regeln

### Sicherheit
- Keine Secrets, Passwörter, Tokens oder Zugangsdaten im Code, in Tests, Logs oder Kommentaren.
  Konfiguration ausschließlich über `os.environ`; neue Variablen in `.env.example` dokumentieren.
- Die Datei `.env` niemals lesen, ausgeben oder committen.
- Datenbankzugriffe nur parametrisiert bzw. über ein ORM, niemals per String-Verkettung.
- Benutzereingaben immer validieren. Jinja2-Autoescaping nie mit `|safe` oder `Markup` umgehen,
  außer der Inhalt ist nachweislich vertrauenswürdig (dann begründen).
- Kein `eval`, `exec`, `pickle` mit fremden Daten, kein `subprocess` mit `shell=True`.
- Debug-Modus nie in Produktion. Fehlerseiten zeigen keine Stacktraces.
- Seiten mit internen Daten brauchen Authentifizierung. Wenn unklar ist, wer zugreifen darf: nachfragen.

### Abhängigkeiten
- Neue Pakete nur nach Rückfrage hinzufügen. Vorher prüfen, dass das Paket auf PyPI existiert,
  gepflegt wird und verbreitet ist (Schutz vor erfundenen oder ähnlich benannten Paketen).
- Immer exakt pinnen (`paket==x.y.z`) in `requirements.txt` bzw. `requirements-dev.txt`.

### Code-Qualität
- Jede neue Funktion und jeder Bugfix bekommt Tests. Die Coverage-Grenze in `pyproject.toml`
  wird nie gesenkt.
- Fehler behandeln und mit `app.logger` bzw. `logging` protokollieren, ohne personenbezogene
  Daten oder Secrets im Log.
- Bestehende Struktur beibehalten: Routen in Blueprints, Logik nicht in Templates.

### Was du nie tust
- QS-Prüfungen umgehen: kein `--no-verify`, kein Deaktivieren von ruff-, bandit- oder Test-Regeln,
  kein `# noqa` / `# nosec` ohne Begründung im Kommentar.
- `.gitlab-ci.yml`, `.gitlab/`, `renovate.json`, `.pre-commit-config.yaml`, `.claude/`, `pyproject.toml`,
  `.python-version` oder die Skripte in `scripts/` ändern,
  ohne dass dies ausdrücklich verlangt wurde.
- Force-Push oder direkter Push auf `main`.

## Definition of Done

Eine Aufgabe ist erst fertig, wenn:
1. `python -m pre_commit run --all-files` und `python -m pytest` lokal grün sind,
2. neue Umgebungsvariablen in `.env.example` und neue Funktionen im README beschrieben sind,
3. `APP_INFO.md` aktuell ist, falls sich Zweck, Daten oder Nutzerkreis geändert haben.
