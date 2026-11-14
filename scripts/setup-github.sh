#!/usr/bin/env bash
# Richtet die verbindliche QS auf GitHub für ein Repository ein:
# Merge-Einstellungen und geschützter Branch "main" (kein direkter Push, kein Force-Push,
# Änderungen nur per Pull Request mit mindestens einer Freigabe durch eine andere Person).
#
# Voraussetzungen:
#   - GitHub CLI installiert und angemeldet: gh auth login
#   - Admin-Recht im Repository
#   - Branch "main" existiert bereits (erster Push ist erfolgt)
#   - Für private Repositories ist der Branch-Schutz nur mit GitHub Pro/Team/Enterprise
#     verfügbar. Ohne passenden Plan meldet das Skript eine Warnung.
#
# Aufruf im Repo-Verzeichnis (Git Bash):   bash scripts/setup-github.sh
# oder für ein anderes Repository:         bash scripts/setup-github.sh MBeCon/mein-repo

set -euo pipefail

REPO="${1:-$(gh repo view --json nameWithOwner -q .nameWithOwner)}"
BRANCH="main"

echo "==> Repository: ${REPO}"

warn() { echo "    WARNUNG: $*" >&2; }

echo "==> Merge-Einstellungen (nur Squash-Merge, Branch nach Merge löschen)"
gh api -X PATCH "repos/${REPO}" \
  -F allow_squash_merge=true \
  -F allow_merge_commit=false \
  -F allow_rebase_merge=false \
  -F delete_branch_on_merge=true \
  --silent

echo "==> Geschützter Branch '${BRANCH}': nur per Pull Request, 1 Freigabe, kein Force-Push"
if ! gh api -X PUT "repos/${REPO}/branches/${BRANCH}/protection" --silent --input - <<'JSON'
{
  "required_status_checks": null,
  "enforce_admins": true,
  "required_pull_request_reviews": {
    "required_approving_review_count": 1,
    "dismiss_stale_reviews": true
  },
  "restrictions": null,
  "required_conversation_resolution": true,
  "allow_force_pushes": false,
  "allow_deletions": false
}
JSON
then
  warn "Branch-Schutz konnte nicht gesetzt werden (privates Repo ohne GitHub Pro/Team, fehlende Admin-Rechte oder Branch '${BRANCH}' fehlt)."
  warn "Dann gilt das Vier-Augen-Prinzip organisatorisch: nie direkt auf main, Merge nie durch den Autor selbst."
fi

echo
echo "Fertig. Bitte noch manuell prüfen:"
echo "  - Settings > Collaborators and teams: Autoren mit Write, Freigeber mit Maintain/Admin"
echo "  - Settings > Secrets and variables > Actions: Secrets für das Deployment hinterlegen"
echo "  - Sobald eine CI-Pipeline (GitHub Actions) existiert: deren Checks als 'required' eintragen"
echo "  - APP_INFO.md ausfüllen"
