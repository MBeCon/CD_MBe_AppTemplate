#!/usr/bin/env bash
# Legt aus dieser Vorlage ein neues Anwendungsprojekt auf GitHub an.
#
# Ablauf (Git Bash):
#   git clone https://github.com/MBeCon/CD_MBe_AppTemplate.git CD_MBe_<AppName>
#   cd CD_MBe_<AppName>
#   bash scripts/new-app.sh                # Repo-Name = Ordnername, Organisation MBeCon
#   bash scripts/new-app.sh andere-org     # optional andere GitHub-Organisation bzw. Benutzer
#
# Das Skript
#   1. merkt sich den Vorlagen-Stand (Commit),
#   2. entfernt die Git-Historie der Vorlage,
#   3. legt ein neues Repo mit einem ersten Commit an,
#   4. erzeugt das private Repository auf GitHub und lädt den ersten Stand hoch (gh repo create).
# Voraussetzung: GitHub CLI angemeldet (gh auth login) und Recht, in der Organisation
# Repositories anzulegen.

set -euo pipefail

OWNER="${1:-${GITHUB_OWNER:-MBeCon}}"
NAME="$(basename "$PWD")"
TEMPLATE_NAME="CD_MBe_AppTemplate"
TEMPLATE_LC="$(echo "$TEMPLATE_NAME" | tr '[:upper:]' '[:lower:]')"

fail() { echo "FEHLER: $*" >&2; exit 1; }

[ -f scripts/new-app.sh ] && [ -f app/__init__.py ] || fail "Bitte im Wurzelordner der geklonten Vorlage ausführen."
[ "$(echo "$NAME" | tr '[:upper:]' '[:lower:]')" != "$TEMPLATE_LC" ] || fail "Der Ordner heißt noch '$TEMPLATE_NAME'. Vorlage unter dem Namen der neuen App klonen: git clone <url> CD_MBe_<AppName>"
[[ "$NAME" =~ ^[a-zA-Z0-9][a-zA-Z0-9._-]*$ ]] || fail "Ordnername '$NAME' ist kein gültiger GitHub-Repo-Name (nur Buchstaben, Ziffern, . _ -)."
command -v gh >/dev/null || fail "GitHub CLI (gh) nicht gefunden. Installieren: winget install --id GitHub.cli, danach: gh auth login"
gh auth status >/dev/null 2>&1 || fail "Nicht bei GitHub angemeldet. Bitte zuerst: gh auth login"

ORIGIN="$(git remote get-url origin 2>/dev/null || true)"
# Vergleich ohne Groß-/Kleinschreibung (GitHub: MBeCon/CD_MBe_AppTemplate)
case "$(echo "$ORIGIN" | tr '[:upper:]' '[:lower:]')" in
  *"/${TEMPLATE_LC}.git"|*"/${TEMPLATE_LC}") ;;
  *) fail "Dieser Ordner ist kein frischer Klon von ${TEMPLATE_NAME} (origin: ${ORIGIN:-keins}). Abbruch, damit keine Historie verloren geht." ;;
esac
[ -z "$(git status --porcelain)" ] || fail "Es gibt nicht committete Änderungen. Bitte frisch klonen."

TEMPLATE_SHA="$(git rev-parse --short HEAD)"

echo "Neues Repository: ${OWNER}/${NAME} (privat)"
echo "Vorlagen-Stand:   ${TEMPLATE_NAME}@${TEMPLATE_SHA}"
read -r -p "Fortfahren? [j/N] " answer
[[ "$answer" =~ ^[jJyY]$ ]] || fail "Abgebrochen."

rm -rf .git
git init -q -b main
git add -A
git commit -q -m "Start aus ${TEMPLATE_NAME}@${TEMPLATE_SHA}"

echo "==> Repository auf GitHub anlegen und hochladen …"
if ! gh repo create "${OWNER}/${NAME}" --private --source . --remote origin --push; then
  echo
  echo "Anlegen fehlgeschlagen. Häufige Ursachen:"
  echo "  - Repository ${OWNER}/${NAME} existiert bereits"
  echo "  - fehlende Rechte in der Organisation ${OWNER}"
  echo "  - nicht angemeldet: gh auth login"
  echo "Alternativ das leere Repository auf github.com anlegen und dann:"
  echo "  git remote add origin https://github.com/${OWNER}/${NAME}.git && git push -u origin main"
  exit 1
fi

echo
echo "Fertig: https://github.com/${OWNER}/${NAME}"
echo "Weiter mit der README: Umgebung einrichten, pyproject.toml/APP_INFO.md anpassen,"
echo "danach einmalig: scripts\\4_github_einrichten.bat (Git Bash: bash scripts/setup-github.sh)"
