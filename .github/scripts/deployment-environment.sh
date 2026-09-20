#!/usr/bin/env bash
set -euo pipefail

if [[ "$RAW_BRANCH" == "master" ]]; then
  {
    echo "VITE_DEPLOYMENT_URL="
    echo "DOCS_DEPLOYMENT_URL=https://rescript-lang.org"
  } >> "$GITHUB_ENV"
else
  SAFE_BRANCH=$(echo "$RAW_BRANCH" | tr '[:upper:]' '[:lower:]' | sed -E 's/[^a-z0-9-]+/-/g; s/^-+//; s/-+$//; s/-+/-/g')
  SAFE_BRANCH="${SAFE_BRANCH:0:28}"
  {
    echo "SAFE_BRANCH=$SAFE_BRANCH"
    echo "VITE_DEPLOYMENT_URL=https://${SAFE_BRANCH}.rescript-lang.pages.dev"
    echo "DOCS_DEPLOYMENT_URL=https://${SAFE_BRANCH}.rescript-lang.pages.dev"
  } >> "$GITHUB_ENV"
fi
