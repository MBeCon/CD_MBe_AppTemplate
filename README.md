# CD_te_app_template

Vorlage für interne te-Anwendungen aus dem Citizen Development (Python/Flask, Docker,
GitLab-Pipeline). Jedes neue Projekt startet aus diesem Template. Damit ist die
Qualitätssicherung von Anfang an eingebaut und muss nicht pro Projekt neu erfunden werden.

**Projekt auf GitLab:** `https://gitlab.technosert.com/technosert/cd_te_app_template`
(GitLab Community Edition, selbst betrieben).

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

Ausführliche Anleitung mit allen Schritten: PDF **„Neues Projekt starten“**
(`CD_te_Neues-Projekt_Vorgangsbeschreibung.pdf`). Kurzfassung für Windows, alle Befehle im
VS-Code-Terminal:

GitLab CE kennt keine eigenen Projektvorlagen („Create from template“ ist eine Premium-Funktion).
Neue Projekte entstehen deshalb per Skript aus dem aktuellen Stand von `main` dieser Vorlage:

1. Vorlage unter dem Namen der neuen Anwendung klonen und das GitLab-Projekt anlegen:
   ```bash
   git clone https://gitlab.technosert.com/technosert/cd_te_app_template.git CD_te_<AppName>
   cd CD_te_<AppName>
   scripts\0_neues_projekt_anlegen.bat      # macOS/Linux bzw. Git Bash: bash scripts/new-app.sh
   code .
   ```
   Das Skript entfernt die Historie der Vorlage, legt einen ersten Commit an und erzeugt per Push
   das private Projekt `technosert/datawarehousehub/applications/CD_te_<AppName>` auf GitLab. Der Commit nennt
   den Vorlagen-Stand, aus dem das Projekt entstanden ist.
2. Python und Umgebung einrichten:
   ```bash
   scripts\1_python_installieren.bat        # Python 3.13 aus .python-version (danach VS Code neu starten)
   scripts\2_umgebung_einrichten.bat        # .venv, Pakete, pre-commit, .env mit SECRET_KEY, Tests
   ```
   macOS/Linux: `bash scripts/setup-dev.sh`.
3. Starten und ansehen: `python -m flask --app wsgi run --debug` → http://127.0.0.1:5000
4. Anpassen: App-Titel in `app/templates/base.html` (`{% block app_title %}`), Projektname in
   `pyproject.toml`, `README.md`, `APP_INFO.md` ausfüllen, `.gitlab/CODEOWNERS` auf den App-Owner setzen.
5. Hochladen: `scripts\3_aenderungen_hochladen.bat` (Branch, Commit, Push, Merge Request).
6. Einmalig durch einen Maintainer, nachdem die Pipeline einmal gelaufen ist:
   ```bash
   scripts\4_gitlab_einrichten.bat        # Git Bash: bash scripts/setup-gitlab.sh
   ```

## Täglicher Ablauf

```bash
git switch main
git pull
claude                                    # mit Claude Code entwickeln
python -m pytest
# In Claude Code: /te-cd-qs:te-cd-qs-review  → automatischer + inhaltlicher Review mit Urteil
scripts\3_aenderungen_hochladen.bat       # Branch, Commit, Push, Merge Request
# Merge Request → Pipeline grün + Merge durch einen Maintainer (nie der Autor) → Deployment
```

Lokal starten: `python -m flask --app wsgi run --debug`, Container testen: `docker compose up --build`.

## Struktur

```
app/                    Flask-Anwendung (Factory, Blueprints, Templates)
app/static/             technosert-Design: css/style.css, js/app.js, images/technosert_logo_white.png
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
                        GitLab-QS einrichten
scripts/setup-dev.*     Einrichtung (Windows: .ps1, macOS/Linux: .sh)
scripts/new-app.sh      Neues Projekt aus dieser Vorlage anlegen
scripts/setup-gitlab.sh Geschützter Branch & Merge-Regeln per glab CLI (Windows: 4_gitlab_einrichten.bat)
scripts/pytest_vor_push.py  Tests vor dem Push immer mit dem Python aus .venv
APP_INFO.md             App-Steckbrief (Owner, Daten, Risiko) für das App-Register
```

## Hinweise

- **GitLab Community Edition:** Geschützter Branch, „Pipelines must succeed“ und „alle Diskussionen
  erledigt“ sind verbindlich. Pflicht-Freigaben, Code-Owner-Pflicht und Push-Regeln gibt es in CE nicht.
  Das Vier-Augen-Prinzip gilt daher organisatorisch: **Nur Maintainer mergen, nie der Autor selbst.**
  `setup-gitlab.sh` erlaubt das Mergen nach `main` nur Maintainern.
- **Secrets:** gitleaks in pre-commit und Pipeline deckt das Risiko ab (Secret Push Protection gibt
  es in CE nicht).
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
