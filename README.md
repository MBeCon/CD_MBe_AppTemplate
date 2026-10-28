# CD_te_app_template

Vorlage für interne te-Anwendungen aus dem Citizen Development (Python/Flask, Docker,
GitLab-Pipeline). Jedes neue Projekt startet aus diesem Template. Damit ist die
Qualitätssicherung von Anfang an eingebaut und muss nicht pro Projekt neu erfunden werden.

**Projekt auf GitLab:** `https://gitlab.technosert.com/datascience/core/applications/CD_te_app_template`
(GitLab Community Edition, selbst betrieben).

## Zusammenspiel mit `datascience/core/applications/CD_te_skills`

| Repo | Rolle | Wie genutzt |
|---|---|---|
| `datascience/core/applications/CD_te_skills` | **Wissen für Claude**: Skills `te-cd-qs-review` (Review) und `te-cd-app-design` (Design) im Plugin `te-cd-qs` | Einmal pro Entwickler installiert (`claude plugin install te-cd-qs@CD_te_skills`), aktualisiert sich selbst |
| `datascience/core/applications/CD_te_app_template` (dieses Repo) | **Kopiervorlage**: Pipeline, pre-commit, `CLAUDE.md`, Hooks, Dockerfile, App-Grundgerüst, App-Steckbrief, Verweis auf CD_te_skills | Pro neuer Anwendung einmal kopiert (`scripts/new-app.sh`) |

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

GitLab CE kennt keine eigenen Projektvorlagen („Create from template“ ist eine Premium-Funktion).
Neue Projekte entstehen deshalb per Skript aus dem aktuellen Stand von `main` dieser Vorlage:

1. Vorlage unter dem Namen der neuen Anwendung klonen und das Skript ausführen (Git Bash):
   ```bash
   git clone https://gitlab.technosert.com/datascience/core/applications/CD_te_app_template.git meine-app
   cd meine-app
   bash scripts/new-app.sh
   ```
   Das Skript entfernt die Historie der Vorlage, legt einen ersten Commit an und erzeugt per Push
   das private Projekt `datascience/core/applications/meine-app` auf GitLab. Der Commit nennt den Vorlagen-Stand,
   aus dem das Projekt entstanden ist.
2. Lokal einrichten:
   ```bash
   python -m venv .venv
   source .venv/bin/activate          # Windows: .venv\Scripts\activate
   pip install -r requirements-dev.txt
   pre-commit install
   cp .env.example .env               # SECRET_KEY setzen
   ```
3. Anpassen: Projektname in `pyproject.toml`, `APP_INFO.md` ausfüllen,
   Platzhalter in `.gitlab/CODEOWNERS` ersetzen, Deploy-Schritt in `.gitlab-ci.yml` einsetzen.
4. Ersten Push durchführen, Pipeline einmal laufen lassen, dann die GitLab-QS aktivieren:
   ```bash
   bash scripts/setup-gitlab.sh
   ```

## Täglicher Ablauf

```bash
git switch -c feature/meine-aenderung
# … mit Claude Code entwickeln …
pytest
pre-commit run --all-files
# In Claude Code: /te-cd-qs:te-cd-qs-review  → automatischer + inhaltlicher Review mit Urteil
git push -u origin feature/meine-aenderung
# Merge Request öffnen → Pipeline grün + Freigabe durch einen Kollegen → Squash-Merge → Deployment
```

Lokal starten: `flask --app wsgi run --debug`, Container testen: `docker compose up --build`.

## Struktur

```
app/                    Flask-Anwendung (Factory, Blueprints, Templates)
tests/                  pytest-Tests
wsgi.py                 Einstiegspunkt für gunicorn
Dockerfile              Produktions-Image (non-root, Health-Check)
CLAUDE.md               Verbindliche Regeln für Claude Code
.claude/                Hooks, Rechte und Verweis auf das QS-Plugin te-cd-qs
.pre-commit-config.yaml Lokale Checks
.gitlab-ci.yml          CI/CD-Pipeline
.gitlab/                MR-Template, CODEOWNERS
renovate.json           Automatische Update-MRs (Renovate)
scripts/new-app.sh      Neues Projekt aus dieser Vorlage anlegen
scripts/setup-gitlab.sh Geschützter Branch & Merge-Regeln per glab CLI
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
- **Katalog-Adresse:** `https://gitlab.technosert.com/datascience/core/applications/CD_te_skills.git`. Zieht der Server
  oder die Gruppe um, die Adresse überall anpassen (auch in `.claude/settings.json`).
- **Claude-Code-Hooks** rufen `python` auf. Auf macOS ggf. in `.claude/settings.json`
  auf `python3` ändern.
- **Coverage-Grenze** (70 %) steht in `pyproject.toml`. Sie darf erhöht, aber nicht gesenkt werden.
- **Trivy-Befunde** ohne verfügbaren Fix werden ignoriert (`--ignore-unfixed`). Begründete
  Ausnahmen in einer `.trivyignore` mit Kommentar dokumentieren.

## QS-Review über das Plugin `te-cd-qs`

Der QS-Review-Skill liegt **nicht** in diesem Repo, sondern zentral im internen
Plugin-Katalog **`datascience/core/applications/CD_te_skills`**. So nutzen alle Projekte immer dieselbe, geprüfte Version.

`.claude/settings.json` verweist bereits auf den Katalog und aktiviert das Plugin
(`extraKnownMarketplaces`, `enabledPlugins`, Auto-Update an). Beim ersten Öffnen des Projekts
in Claude Code den Ordner als vertrauenswürdig bestätigen. Falls das Plugin danach noch
nicht verfügbar ist, einmalig ausführen:

```bash
glab auth login --hostname gitlab.technosert.com  # Zugriff auf das private Katalog-Repo (Git-Credential-Helper aktivieren)
claude plugin marketplace add https://gitlab.technosert.com/datascience/core/applications/CD_te_skills.git
claude plugin install te-cd-qs@CD_te_skills
```

Aufruf in Claude Code: `/te-cd-qs:te-cd-qs-review` oder einfach „Bitte vor dem MR reviewen“.
Der Review ersetzt nicht das Review durch einen Kollegen, sondern bereitet es vor.
Details, Updates und neue Skills: README im Repo `datascience/core/applications/CD_te_skills`.
