#!/usr/bin/env bash
set -euo pipefail

# Remove older Lighthouse artifacts for this branch after preserving the
# artifact uploaded by the current workflow run.
gh api --method GET \
  "/repos/${GITHUB_REPOSITORY}/actions/artifacts" \
  -f name="$LIGHTHOUSE_ARTIFACT_NAME" \
  -f per_page=100 \
  --jq '.artifacts[].id' | while read -r ARTIFACT_ID; do
    if [[ "$ARTIFACT_ID" != "$CURRENT_ARTIFACT_ID" ]]; then
      gh api --method DELETE "/repos/${GITHUB_REPOSITORY}/actions/artifacts/${ARTIFACT_ID}"
    fi
  done
