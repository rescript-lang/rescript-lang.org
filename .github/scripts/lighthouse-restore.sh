#!/usr/bin/env bash
set -euo pipefail

mkdir -p .lighthouse-target

ARCHIVE_PATH="$RUNNER_TEMP/lighthouse-target.zip"
DOWNLOAD_ERROR="$RUNNER_TEMP/lighthouse-target-error.log"

for ATTEMPT in 1 2 3; do
  ARTIFACT_ID=$(gh api --method GET \
    "/repos/${GITHUB_REPOSITORY}/actions/artifacts" \
    -f name="$LIGHTHOUSE_TARGET_ARTIFACT_NAME" \
    -f per_page=100 \
    --jq '.artifacts | map(select(.expired == false)) | sort_by(.created_at) | last | .id // empty')

  if [[ -z "$ARTIFACT_ID" ]]; then
    echo "No Lighthouse baseline found for target branch $LIGHTHOUSE_TARGET_BRANCH"
    exit 0
  fi

  if gh api "/repos/${GITHUB_REPOSITORY}/actions/artifacts/${ARTIFACT_ID}/zip" > "$ARCHIVE_PATH" 2> "$DOWNLOAD_ERROR"; then
    unzip -q "$ARCHIVE_PATH" -d .lighthouse-target
    exit 0
  else
    DOWNLOAD_STATUS=$?
  fi

  cat "$DOWNLOAD_ERROR" >&2
  rm -f "$ARCHIVE_PATH"
  if ! grep -Eq '^gh: .* \(HTTP (404|410)\)$' "$DOWNLOAD_ERROR"; then
    exit "$DOWNLOAD_STATUS"
  fi

  echo "Lighthouse baseline artifact $ARTIFACT_ID disappeared during download (attempt $ATTEMPT of 3)"
done

echo "No Lighthouse baseline available for target branch $LIGHTHOUSE_TARGET_BRANCH after 3 attempts"
