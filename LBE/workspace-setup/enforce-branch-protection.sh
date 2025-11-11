#!/usr/bin/env bash

set -euo pipefail

# LBE Services - Branch Protection Enforcer
#
# This script configures consistent protection settings for the develop and main
# branches across multiple repositories via the GitHub CLI (gh). Update the
# configuration section below or pass repository names as arguments, then run:
#   ./enforce-branch-protection.sh repo-one repo-two
#
# Environment variables can override most defaults (see usage output).

usage() {
  cat <<'EOF'
Usage: ./enforce-branch-protection.sh [repo-one repo-two ...]

Arguments:
  repo-one repo-two ...   Optional positional list of repositories that live
                          under <org>/<repo>. When omitted, the script falls
                          back to SERVICE_REPOS or AUTO_DISCOVER.

Key environment overrides:
  GITHUB_ORG             Target GitHub organization/owner (default: your-org)
  GH_HOST                GitHub host if you use GHES (default: github.com)
  DEV_BRANCH             Name of the team branch (default: develop)
  MAIN_BRANCH            Name of the protected branch (default: main)
  DRY_RUN=true           Preview payloads without calling the API
  AUTO_DISCOVER=true     Use gh repo list + REPO_PATTERN to build repo list
  REPO_PATTERN           jq regex passed to gh repo list when auto-discovering

Examples:
  GITHUB_ORG=my-org ./enforce-branch-protection.sh billing-service ledger-service
  GITHUB_ORG=my-org AUTO_DISCOVER=true REPO_PATTERN='-service$' ./enforce-branch-protection.sh
EOF
}

if [[ "${1:-}" == "--help" || "${1:-}" == "-h" ]]; then
  usage
  exit 0
fi

# -----------------------------------------------------------------------------
# Configuration
# -----------------------------------------------------------------------------

GH_HOST="${GH_HOST:-github.com}"
GITHUB_ORG="${GITHUB_ORG:-LaborManagement}"
DEV_BRANCH="${DEV_BRANCH:-develop}"
MAIN_BRANCH="${MAIN_BRANCH:-main}"

# Teams/users/apps allowed to push directly to develop.
DEV_ALLOWED_TEAMS=("DevServ") # team slug, not display name
DEV_ALLOWED_USERS=()
DEV_ALLOWED_APPS=()

# Teams/users/apps allowed to push directly to main (leave empty to require PRs).
MAIN_ALLOWED_TEAMS=()
MAIN_ALLOWED_USERS=("@rahulcharvekar")
MAIN_ALLOWED_APPS=()

# Optional: actors allowed to bypass pull request requirements on main.
MAIN_BYPASS_TEAMS=()
MAIN_BYPASS_USERS=("rahulcharvekar")
MAIN_BYPASS_APPS=()

MAIN_REQUIRED_REVIEWS="${MAIN_REQUIRED_REVIEWS:-0}"

DEV_ALLOW_FORCE_PUSHES="${DEV_ALLOW_FORCE_PUSHES:-false}"
DEV_ALLOW_DELETIONS="${DEV_ALLOW_DELETIONS:-false}"
MAIN_ALLOW_FORCE_PUSHES="${MAIN_ALLOW_FORCE_PUSHES:-false}"
MAIN_ALLOW_DELETIONS="${MAIN_ALLOW_DELETIONS:-false}"

AUTO_DISCOVER="${AUTO_DISCOVER:-false}"
REPO_PATTERN="${REPO_PATTERN:-}"
REPO_FETCH_LIMIT="${REPO_FETCH_LIMIT:-200}"
DRY_RUN="${DRY_RUN:-false}"

# Populate this list when not passing repo names as arguments or using
# AUTO_DISCOVER. Each entry should be the repository name without the org.
SERVICE_REPOS=(
    "documentation"
    "auth-service"
    "payment-flow-service"
    "recon-service"
    "shared-lib"
    "admin-ui"
)

# -----------------------------------------------------------------------------

require_gh() {
  if ! command -v gh >/dev/null 2>&1; then
    echo "gh (GitHub CLI) is required" >&2
    exit 1
  fi

  if ! gh auth status --hostname "$GH_HOST" >/dev/null 2>&1; then
    echo "Please run 'gh auth login --hostname $GH_HOST' before executing this script" >&2
    exit 1
  fi
}

discover_repos() {
  local jq_filter='.[]'
  if [[ -n "$REPO_PATTERN" ]]; then
    jq_filter+=" | select(.name | test(\"$REPO_PATTERN\"))"
  fi
  jq_filter+=' | .name'

  mapfile -t SERVICE_REPOS < <(
    gh repo list "$GITHUB_ORG" \
      --hostname "$GH_HOST" \
      --limit "$REPO_FETCH_LIMIT" \
      --json name \
      --jq "$jq_filter"
  )
}

json_array() {
  local items=()
  if [[ $# -gt 0 ]]; then
    items=("$@")
  fi

  printf '['
  local first=1
  for item in "${items[@]}"; do
    [[ -z "$item" ]] && continue
    if (( first )); then
      first=0
    else
      printf ','
    fi
    printf '"%s"' "$item"
  done
  printf ']'
}

build_restrictions() {
  local users_json="$1"
  local teams_json="$2"
  local apps_json="$3"

  cat <<JSON
{
  "users": ${users_json},
  "teams": ${teams_json},
  "apps": ${apps_json}
}
JSON
}

build_payload() {
  local restrictions_json="$1"
  local pr_reviews_json="$2"
  local allow_force_pushes="$3"
  local allow_deletions="$4"

  cat <<JSON
{
  "required_status_checks": null,
  "enforce_admins": true,
  "required_pull_request_reviews": ${pr_reviews_json},
  "restrictions": ${restrictions_json},
  "allow_force_pushes": ${allow_force_pushes},
  "allow_deletions": ${allow_deletions},
  "required_linear_history": true,
  "allow_fork_syncing": false,
  "block_creations": true
}
JSON
}

configure_branch() {
  local repo="$1"
  local branch="$2"
  local payload="$3"

  echo "  - ${branch}"

  if [[ "$DRY_RUN" == "true" ]]; then
    echo "    [dry-run] ${repo}:${branch}"
    echo "$payload"
    return 0
  fi

  gh api \
    --hostname "$GH_HOST" \
    -X PUT \
    -H "Accept: application/vnd.github+json" \
    -H "X-GitHub-Api-Version: 2022-11-28" \
    "repos/${GITHUB_ORG}/${repo}/branches/${branch}/protection" \
    --input - <<<"$payload" >/dev/null
}

# Build repository list
if [[ $# -gt 0 ]]; then
  SERVICE_REPOS=("$@")
elif [[ "$AUTO_DISCOVER" == "true" ]]; then
  discover_repos
fi

if [[ ${#SERVICE_REPOS[@]} -eq 0 ]]; then
  echo "No repositories specified. Add entries to SERVICE_REPOS, pass them as arguments, or enable AUTO_DISCOVER." >&2
  exit 1
fi

require_gh

DEV_USERS_JSON=$(json_array "${DEV_ALLOWED_USERS[@]-}")
DEV_TEAMS_JSON=$(json_array "${DEV_ALLOWED_TEAMS[@]-}")
DEV_APPS_JSON=$(json_array "${DEV_ALLOWED_APPS[@]-}")
DEV_RESTRICTIONS=$(build_restrictions "$DEV_USERS_JSON" "$DEV_TEAMS_JSON" "$DEV_APPS_JSON")
DEV_PR_REVIEWS="null"
DEV_PAYLOAD=$(build_payload "$DEV_RESTRICTIONS" "$DEV_PR_REVIEWS" "$DEV_ALLOW_FORCE_PUSHES" "$DEV_ALLOW_DELETIONS")

MAIN_USERS_JSON=$(json_array "${MAIN_ALLOWED_USERS[@]-}")
MAIN_TEAMS_JSON=$(json_array "${MAIN_ALLOWED_TEAMS[@]-}")
MAIN_APPS_JSON=$(json_array "${MAIN_ALLOWED_APPS[@]-}")
MAIN_RESTRICTIONS=$(build_restrictions "$MAIN_USERS_JSON" "$MAIN_TEAMS_JSON" "$MAIN_APPS_JSON")
read -r -d '' MAIN_PR_REVIEWS <<JSON || true
{
  "dismissal_restrictions": {
    "users": [],
    "teams": []
  },
  "dismiss_stale_reviews": true,
  "require_code_owner_reviews": true,
  "required_approving_review_count": ${MAIN_REQUIRED_REVIEWS}
}
JSON
MAIN_PAYLOAD=$(build_payload "$MAIN_RESTRICTIONS" "$MAIN_PR_REVIEWS" "$MAIN_ALLOW_FORCE_PUSHES" "$MAIN_ALLOW_DELETIONS")

echo "Configuring branch protection on ${#SERVICE_REPOS[@]} repositories in ${GITHUB_ORG} (host: ${GH_HOST})"
[[ "$DRY_RUN" == "true" ]] && echo "Dry-run mode enabled. No changes will be sent to GitHub."

overall_status=0

for repo in "${SERVICE_REPOS[@]}"; do
  printf '\nRepository: %s/%s\n' "$GITHUB_ORG" "$repo"

  if configure_branch "$repo" "$DEV_BRANCH" "$DEV_PAYLOAD"; then
    echo "    ${DEV_BRANCH} branch updated"
  else
    echo "    failed to update ${DEV_BRANCH}" >&2
    overall_status=1
    continue
  fi

  if configure_branch "$repo" "$MAIN_BRANCH" "$MAIN_PAYLOAD"; then
    echo "    ${MAIN_BRANCH} branch updated"
  else
    echo "    failed to update ${MAIN_BRANCH}" >&2
    overall_status=1
  fi
done

exit $overall_status
