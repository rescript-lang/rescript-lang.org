#!/usr/bin/env bash
set -euo pipefail

# Export stable artifact keys for the current branch and its comparison branch;
# pull requests compare against their live base branch.
REPOSITORY_ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)

if [[ "$GITHUB_EVENT_NAME" == "pull_request" ]]; then
  RAW_TARGET_BRANCH=$(gh api "/repos/${GITHUB_REPOSITORY}/pulls/${PR_NUMBER}" --jq '.base.ref')
else
  RAW_TARGET_BRANCH="$RAW_BRANCH"
fi

ARTIFACT_NAME=$(node "$REPOSITORY_ROOT/apps/docs/scripts/lighthouse-report.mjs" artifact-name "$RAW_BRANCH")
TARGET_ARTIFACT_NAME=$(node "$REPOSITORY_ROOT/apps/docs/scripts/lighthouse-report.mjs" artifact-name "$RAW_TARGET_BRANCH")

{
  echo "LIGHTHOUSE_ARTIFACT_NAME=$ARTIFACT_NAME"
  echo "LIGHTHOUSE_BRANCH=$RAW_BRANCH"
  echo "LIGHTHOUSE_TARGET_ARTIFACT_NAME=$TARGET_ARTIFACT_NAME"
  echo "LIGHTHOUSE_TARGET_BRANCH=$RAW_TARGET_BRANCH"
} >> "$GITHUB_ENV"
