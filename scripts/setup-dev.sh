#!/usr/bin/env bash
# Richtet die Entwicklungsumgebung unter macOS/Linux ein (Gegenstück zu setup-dev.ps1).
# Aufruf im Projektordner: bash scripts/setup-dev.sh
set -euo pipefail
cd "$(dirname "$0")/.."

VERSION="$(head -n1 .python-version | tr -d '[:space:]')"
PY="python${VERSION}"
command -v "$PY" >/dev/null || { echo "FEHLER: ${PY} nicht gefunden (z. B. brew install python@${VERSION})." >&2; exit 1; }

if [ -x .venv/bin/python ]; then
  HAVE="$(.venv/bin/python -c 'import sys; print(f"{sys.version_info[0]}.{sys.version_info[1]}")')"
  [ "$HAVE" = "$VERSION" ] || { echo "FEHLER: .venv nutzt Python ${HAVE} statt ${VERSION}. Ordner .venv löschen und erneut starten." >&2; exit 1; }
else
  echo "==> .venv anlegen"; "$PY" -m venv .venv
fi

echo "==> Pakete installieren"
.venv/bin/python -m pip install --upgrade --quiet pip
.venv/bin/python -m pip install --quiet -r requirements-dev.txt

echo "==> pre-commit einrichten"
.venv/bin/python -m pre_commit install

if [ ! -f .env ]; then
  KEY="$(.venv/bin/python -c 'import secrets; print(secrets.token_hex(32))')"
  sed "s/^SECRET_KEY=.*/SECRET_KEY=${KEY}/" .env.example > .env
  echo "==> .env erzeugt (SECRET_KEY zufällig gesetzt)"
fi

echo "==> Tests"
.venv/bin/python -m pytest -q
echo "Fertig. Neues Terminal öffnen oder: source .venv/bin/activate"
