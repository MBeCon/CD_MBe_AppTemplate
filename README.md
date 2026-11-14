# CD_MBe_AppTemplate („Template“)

Vorlage für interne MBe-Anwendungen aus dem Citizen Development (Python/Flask, Docker).
Jedes neue Projekt startet aus diesem Template. Damit sind Design und Qualitätssicherung von
Anfang an eingebaut und müssen nicht pro Projekt neu erfunden werden.

**Repository auf GitHub:** `https://github.com/MBeCon/CD_MBe_AppTemplate`

## Design (UI/UX) wie MBeTradingHub

Oberfläche und Bedienung entsprechen 1:1 MBeTradingHub (Skill `mbe-design`):

- Weiße Kopfzeile mit violetter Unterlinie, Logo links (→ Startseite), App-Name mittig, Umgebungs-Badge rechts
- Menüleiste links (einklappbar mit &#8942;, Zustand wird gemerkt), Gruppen mit Titeln, „Einstellungen“ ganz unten
- Arbeitsbereich: Seitenkopf → Panels → Tabellen/Formulare, Nebenfunktionen als Popups
- Fußzeile mit Server-Status (`/health`, alle 30 s), Web-Link und Live-Uhr
- Farben `#46067A` (violett) & Co., Schrift Verdana 10–16 px, Zahlen in Courier New rechtsbündig

| Datei | Inhalt |
|---|---|
| `app/static/css/style.css` | komplettes MBe-Stylesheet (nur ergänzen) |
| `app/templates/base.html` | Grundlayout: Kopfzeile, Menü, Arbeitsbereich, Fußzeile |
| `app/templates/beispiel.html` + `js/beispiel.js` | **Seitenmuster** – Kacheln, Seitenkopf, Tabelle mit Suche, Popup, Löschen mit Rückfrage |
| `app/templates/einstellungen.html` | Einstellungsseite (Darstellung, Systeminfos) |
| `app/static/js/app.js` | gemeinsame Helfer (`openModal`, `closeModal`, `escHtml`, `fmtNum`, `withBusy`, `loadingRow`, `emptyRow`, `getSaved`/`save`) |

Wegen der Content-Security-Policy gibt es **kein** `onclick=`/Inline-JavaScript. Statt dessen:
`data-open-modal="xyzModal"`, `data-close-modal="xyzModal"`, `data-action="toggle-sidebar"`,
`data-hide-on-error` (Bild ausblenden) – Seitenlogik per `addEventListener` in `app/static/js/<seite>.js`.

## Zusammenspiel mit `technosert/cd_te_skills`

| Repo | Rolle | Wie genutzt |
|---|---|---|
| `technosert/cd_te_skills` | **Wissen für Claude**: Skills `te-cd-qs-review` (Review) und `te-cd-app-design` (Design) im Plugin `te-cd-qs` | Einmal pro Entwickler installiert (`claude plugin install te-cd-qs@CD_te_skills`), aktualisiert sich selbst |
| `technosert/cd_te_app_template` (dieses Repo) | **Kopiervorlage**: Pipeline, pre-commit, `CLAUDE.md`, Hooks, Dockerfile, App-Grundgerüst, App-Steckbrief, Verweis auf CD_te_skills | Pro neuer Anwendung einmal kopiert (`scripts/new-app.sh`) |

Die Skills sagen Claude, *was gute Qualität ist*. Das Template sorgt dafür, dass jedes Projekt
*so aufgebaut ist und verbindlich geprüft wird*.

## QS-Ebenen im Überblick

| Ebene | Wo | Was | Verbindlich? |
|---|---|---|---|
| 1. Beim Entwickeln | Claude Code (`CLAUDE.md`, `.claude/`) | Projektregeln, ruff nach jeder Änderung, Blockade von `--no-verify` / Push auf main, QS-Review `/te-cd-qs:te-cd-qs-review` (Plugin) | Unterstützend |
| 2. Vor Commit/Push | pre-commit (`.pre-commit-config.yaml`) | ruff, gitleaks, bandit, Dateichecks; pytest vor dem Push | Unterstützend (umgehbar) |
| 3. Im Merge Request | GitLab CI/CD (`.gitlab-ci.yml`) + geschützter Branch | lint, test (Coverage ≥ 70 %), security (bandit, pip-audit), secrets (gitleaks), docker (hadolint, Smoke-Test, Trivy) + Merge durch Maintainer | **Ja – Gate für main** |
| 4. Deployment | Job `deploy` | nur nach Merge auf main und nur bei grünen Checks | **Ja** |
| Laufend | Renovate (`renovate.json`) | wöchentliche Update-MRs für Pakete, Base-Image, CI-Images | Ja (über MR) |

## Neues Projekt anlegen

Kurzfassung für Windows, alle Befehle im VS-Code-Terminal. Voraussetzungen: Git für Windows und
GitHub CLI (`winget install --id GitHub.cli`, danach `gh auth login`).

1. Vorlage unter dem Namen der neuen Anwendung klonen und das GitHub-Repository anlegen:
   ```bash
   git clone https://github.com/MBeCon/CD_MBe_AppTemplate.git CD_MBe_<AppName>
   cd CD_MBe_<AppName>
   scripts\0_neues_projekt_anlegen.bat      # Git Bash: bash scripts/new-app.sh
   code .
   ```
   Das Skript entfernt die Historie der Vorlage, legt einen ersten Commit an und erzeugt mit
   `gh repo create` das private Repository `MBeCon/CD_MBe_<AppName>` auf GitHub. Der Commit nennt
   den Vorlagen-Stand, aus dem das Projekt entstanden ist. Andere Organisation: Name als Parameter.
2. Python und Umgebung einrichten:
   ```bash
   scripts\1_python_installieren.bat        # Python 3.13 aus .python-version (danach VS Code neu starten)
   scripts\2_umgebung_einrichten.bat        # .venv, Pakete, pre-commit, .env mit SECRET_KEY, Tests
   ```
   macOS/Linux: `bash scripts/setup-dev.sh`.
3. Starten und ansehen: `python -m flask --app wsgi run --debug` → http://127.0.0.1:5000
4. Anpassen: App-Name und Untertitel in `app/templates/base.html` (`app_title`, `app_subtitle`),
   Menügruppen, Projektname in `pyproject.toml`, `README.md`, `APP_INFO.md` ausfüllen.
   Neue Seiten nach dem Muster `beispiel.html` anlegen.
5. Hochladen: `scripts\3_aenderungen_hochladen.bat` (Branch, Commit, Push, Pull Request).
6. Einmalig durch einen Admin des Repositorys, nachdem `main` hochgeladen ist:
   ```bash
   scripts\4_github_einrichten.bat        # Git Bash: bash scripts/setup-github.sh
   ```
   Setzt Squash-Merge und schützt `main` (nur per Pull Request mit 1 Freigabe, kein Force-Push).
   Hinweis: Branch-Schutz für private Repositories erfordert GitHub Pro/Team.

## Täglicher Ablauf

```bash
git switch main
git pull
claude                                    # mit Claude Code entwickeln
python -m pytest
# In Claude Code: /te-cd-qs:te-cd-qs-review  → automatischer + inhaltlicher Review mit Urteil
scripts\3_aenderungen_hochladen.bat       # Branch, Commit, Push, Pull Request
# Pull Request → Freigabe durch eine andere Person (nie der Autor) → Merge
```

Lokal starten: `python -m flask --app wsgi run --debug`, Container testen: `docker compose up --build`.

## Struktur

```
app/                    Flask-Anwendung (Factory, Blueprints, Templates)
app/static/             MBe-Design: css/style.css, js/app.js (+ js/<seite>.js), images/MBe_Button_violett.png, favicon.ico
tests/                  pytest-Tests
wsgi.py                 Einstiegspunkt für gunicorn
.python-version         Python-Version (3.13) für die Einrichtungsskripte
Dockerfile              Produktions-Image (non-root, Health-Check)
CLAUDE.md               Verbindliche Regeln für Claude Code
.claude/                Hooks, Rechte und Verweis auf das QS-Plugin te-cd-qs
.vscode/                Gemeinsame Editor-Einstellungen, empfohlene Erweiterungen
.pre-commit-config.yaml Lokale Checks
.gitlab-ci.yml          CI/CD-Pipeline
.gitlab/                MR-Template, CODEOWNERS
renovate.json           Automatische Update-MRs (Renovate)
scripts/0_…4_….bat      Windows: Projekt anlegen, Python installieren, Umgebung einrichten, hochladen,
                        GitHub-QS einrichten
scripts/setup-dev.*     Einrichtung (Windows: .ps1, macOS/Linux: .sh)
scripts/new-app.sh      Neues Projekt aus dieser Vorlage anlegen (GitHub, gh CLI)
scripts/setup-github.sh Geschützter Branch & Merge-Regeln per gh CLI (Windows: 4_github_einrichten.bat)
scripts/pytest_vor_push.py  Tests vor dem Push immer mit dem Python aus .venv
APP_INFO.md             App-Steckbrief (Owner, Daten, Risiko) für das App-Register
```

## Hinweise

- **CI-Pipeline:** Die Pipeline liegt noch als `.gitlab-ci.yml` (GitLab) vor und läuft auf GitHub nicht.
  Bis zur Umstellung auf GitHub Actions gelten lokal pre-commit und `python -m pytest` als Prüfung.
- **Secrets:** gitleaks in pre-commit deckt das Risiko ab; auf GitHub zusätzlich *Secret scanning / Push protection* aktivieren.
- **GitLab-Runner:** Die Pipeline braucht einen Linux-Runner mit Docker-Executor im *privileged*-Modus
  (Job `docker` nutzt Docker-in-Docker).
- **Renovate** braucht einen Renovate-Bot für eure GitLab-Instanz (z. B. *renovate-runner* als
  geplante Pipeline). Ohne Bot bleiben Updates manuell.
- **Katalog-Adresse:** `https://gitlab.technosert.com/technosert/cd_te_skills.git`. Zieht der Server
  oder die Gruppe um, die Adresse überall anpassen (auch in `.claude/settings.json`).
- **Python-Version** steht in `.python-version`, `pyproject.toml`, `Dockerfile` und `.gitlab-ci.yml` –
  nur gemeinsam ändern.
- **Claude-Code-Hooks** rufen `python` auf. Auf macOS ggf. in `.claude/settings.json`
  auf `python3` ändern.
- **Coverage-Grenze** (70 %) steht in `pyproject.toml`. Sie darf erhöht, aber nicht gesenkt werden.
- **Trivy-Befunde** ohne verfügbaren Fix werden ignoriert (`--ignore-unfixed`). Begründete
  Ausnahmen in einer `.trivyignore` mit Kommentar dokumentieren.

## QS-Review über das Plugin `te-cd-qs`

Der QS-Review-Skill liegt **nicht** in diesem Repo, sondern zentral im internen
Plugin-Katalog **`technosert/cd_te_skills`**. So nutzen alle Projekte immer dieselbe, geprüfte Version.

`.claude/settings.json` verweist bereits auf den Katalog und aktiviert das Plugin
(`extraKnownMarketplaces`, `enabledPlugins`, Auto-Update an). Beim ersten Öffnen des Projekts
in Claude Code den Ordner als vertrauenswürdig bestätigen. Falls das Plugin danach noch
nicht verfügbar ist, einmalig ausführen:

```bash
glab auth login --hostname gitlab.technosert.com  # Zugriff auf das private Katalog-Repo (Git-Credential-Helper aktivieren)
claude plugin marketplace add https://gitlab.technosert.com/technosert/cd_te_skills.git
claude plugin install te-cd-qs@CD_te_skills
```

Aufruf in Claude Code: `/te-cd-qs:te-cd-qs-review` oder einfach „Bitte vor dem MR reviewen“.
Der Review ersetzt nicht das Review durch einen Kollegen, sondern bereitet es vor.
Details, Updates und neue Skills: README im Repo `technosert/cd_te_skills`.
