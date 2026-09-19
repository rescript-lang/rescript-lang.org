#!/usr/bin/env bash
set -euo pipefail

mkdir -p .lighthouse-target

ARTIFACT_ID=$(gh api --method GET \
  "/repos/${GITHUB_REPOSITORY}/actions/artifacts" \
  -f name="$LIGHTHOUSE_TARGET_ARTIFACT_NAME" \
  -f per_page=100 \
  --jq '.artifacts | map(select(.expired == false)) | sort_by(.created_at) | last | .id // empty')

if [[ -z "$ARTIFACT_ID" ]]; then
  echo "No Lighthouse baseline found for target branch $LIGHTHOUSE_TARGET_BRANCH"
  exit 0
fi

gh api "/repos/${GITHUB_REPOSITORY}/actions/artifacts/${ARTIFACT_ID}/zip" > "$RUNNER_TEMP/lighthouse-target.zip"
unzip -q "$RUNNER_TEMP/lighthouse-target.zip" -d .lighthouse-target
