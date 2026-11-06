#!/usr/bin/env bash
# Richtet die verbindliche QS auf GitLab für ein neues Projekt ein.
# Ausgelegt für GitLab Community Edition auf gitlab.technosert.com.
#
# Voraussetzungen:
#   - GitLab CLI installiert und angemeldet: glab auth login --hostname gitlab.technosert.com
#   - Rolle Maintainer/Owner im Projekt
#   - Branch "main" existiert bereits (erster Push ist erfolgt)
#   - Die Pipeline ist mindestens einmal gelaufen
#
# Aufruf im Repo-Verzeichnis (Git Bash):   bash scripts/setup-gitlab.sh
# oder für ein anderes Projekt:            bash scripts/setup-gitlab.sh technosert/datawarehousehub/applications/mein-repo
#
# Pflicht-Freigaben, Code-Owner-Pflicht und Push-Regeln gibt es in CE nicht. Das Vier-Augen-Prinzip
# wird organisatorisch umgesetzt: Nur Maintainer dürfen nach main mergen, nie der Autor selbst.

set -euo pipefail

export GITLAB_HOST="${GITLAB_HOST:-gitlab.technosert.com}"

# ":id" ist ein glab-Platzhalter für das Projekt des aktuellen Repos
PROJECT="${1:-:id}"
PROJECT="${PROJECT//\//%2F}"
BRANCH="main"

echo "==> Server: ${GITLAB_HOST} · Projekt: ${1:-(aktuelles Repo)}"

warn() { echo "    WARNUNG: $*" >&2; }

echo "==> Merge-Einstellungen (Squash, lineare Historie, nur mit grüner Pipeline, Diskussionen erledigt)"
glab api -X PUT "projects/${PROJECT}" \
  -f merge_method=ff \
  -f squash_option=default_on \
  -F only_allow_merge_if_pipeline_succeeds=true \
  -F allow_merge_on_skipped_pipeline=false \
  -F only_allow_merge_if_all_discussions_are_resolved=true \
  -F remove_source_branch_after_merge=true \
  --silent

echo "==> Geschützter Branch '${BRANCH}': kein direkter Push, kein Force-Push, Merge nur durch Maintainer"
glab api -X DELETE "projects/${PROJECT}/protected_branches/${BRANCH}" --silent 2>/dev/null || true
glab api -X POST "projects/${PROJECT}/protected_branches" \
  -f name="${BRANCH}" \
  -F push_access_level=0 \
  -F merge_access_level=40 \
  -F allow_force_push=false \
  --silent

echo "==> Environment 'production' für den Deploy-Job"
glab api -X POST "projects/${PROJECT}/environments" -f name=production --silent 2>/dev/null \
  || warn "Environment konnte nicht angelegt werden (existiert evtl. bereits)."

echo
echo "Fertig. Bitte noch manuell prüfen:"
echo "  - .gitlab/CODEOWNERS: \"*\" auf den App-Owner setzen"
echo "  - Manage > Members: Autoren als Developer, Freigeber als Maintainer"
echo "  - Settings > CI/CD > Variables: Secrets für das Deployment (protected + masked) hinterlegen"
echo "  - Settings > CI/CD > Runners: Linux-Runner mit Docker (privileged) verfügbar?"
echo "  - Renovate für das Projekt aktivieren (siehe README)"
echo "  - APP_INFO.md ausfüllen"
