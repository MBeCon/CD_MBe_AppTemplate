#!/usr/bin/env bash
# Legt aus dieser Vorlage ein neues Anwendungsprojekt auf GitLab an.
# Ersatz für „Create from template“, das es in GitLab Community Edition nicht gibt.
#
# Ablauf (Git Bash):
#   git clone https://gitlab.technosert.com/datascience/core/applications/CD_te_app_template.git meine-app
#   cd meine-app
#   bash scripts/new-app.sh              # Projektname = Ordnername
#   bash scripts/new-app.sh andere-gruppe # optional andere GitLab-Gruppe (Pfad)
#
# Das Skript
#   1. merkt sich den Vorlagen-Stand (Commit),
#   2. entfernt die Git-Historie der Vorlage,
#   3. legt ein neues Repo mit einem ersten Commit an,
#   4. erzeugt das private Projekt auf GitLab per Push („push to create“).
# Voraussetzung: glab auth login --hostname gitlab.technosert.com (Git-Credential-Helper „Yes“)
# und Rolle Developer oder höher in der Zielgruppe.

set -euo pipefail

HOST="${GITLAB_HOST:-gitlab.technosert.com}"
GROUP="${1:-datascience/core/applications}"
NAME="$(basename "$PWD")"
TEMPLATE_NAME="CD_te_app_template"

fail() { echo "FEHLER: $*" >&2; exit 1; }

[ -f scripts/new-app.sh ] && [ -f .gitlab-ci.yml ] || fail "Bitte im Wurzelordner der geklonten Vorlage ausführen."
[ "$NAME" != "$TEMPLATE_NAME" ] || fail "Der Ordner heißt noch '$TEMPLATE_NAME'. Vorlage unter dem Namen der neuen App klonen: git clone <url> meine-app"
[[ "$NAME" =~ ^[a-zA-Z0-9][a-zA-Z0-9._-]*$ ]] || fail "Ordnername '$NAME' ist kein gültiger GitLab-Projektpfad (nur Buchstaben, Ziffern, . _ -)."

ORIGIN="$(git remote get-url origin 2>/dev/null || true)"
case "$ORIGIN" in
  *"/${TEMPLATE_NAME}.git"|*"/${TEMPLATE_NAME}") ;;
  *) fail "Dieser Ordner ist kein frischer Klon von ${TEMPLATE_NAME} (origin: ${ORIGIN:-keins}). Abbruch, damit keine Historie verloren geht." ;;
esac
[ -z "$(git status --porcelain)" ] || fail "Es gibt nicht committete Änderungen. Bitte frisch klonen."

TEMPLATE_SHA="$(git rev-parse --short HEAD)"
TARGET="https://${HOST}/${GROUP}/${NAME}.git"

echo "Neues Projekt:   ${GROUP}/${NAME}"
echo "Vorlagen-Stand:  ${TEMPLATE_NAME}@${TEMPLATE_SHA}"
read -r -p "Fortfahren? [j/N] " answer
[[ "$answer" =~ ^[jJyY]$ ]] || fail "Abgebrochen."

rm -rf .git
git init -q -b main
git add -A
git commit -q -m "Start aus ${TEMPLATE_NAME}@${TEMPLATE_SHA}"
git remote add origin "$TARGET"

echo "==> Projekt auf GitLab anlegen (push to create) …"
if ! git push -u origin main; then
  echo
  echo "Push fehlgeschlagen. Häufige Ursachen:"
  echo "  - Projekt ${GROUP}/${NAME} existiert bereits"
  echo "  - fehlende Rechte in der Gruppe ${GROUP} (mindestens Developer nötig)"
  echo "  - nicht angemeldet: glab auth login --hostname ${HOST}"
  echo "Alternativ das leere Projekt in GitLab anlegen und erneut ausführen: git push -u origin main"
  exit 1
fi

echo
echo "Fertig: https://${HOST}/${GROUP}/${NAME}"
echo "Weiter mit der README: venv einrichten, pyproject.toml/APP_INFO.md/CODEOWNERS anpassen,"
echo "nach dem ersten Pipeline-Lauf: bash scripts/setup-gitlab.sh"
