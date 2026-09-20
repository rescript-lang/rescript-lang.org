#!/usr/bin/env bash
set -euo pipefail

# Export the canonical production URL or the branch-specific Pages preview URL
# for later GitHub Actions steps.
if [[ "$RAW_BRANCH" == "master" ]]; then
  {
    echo "VITE_DEPLOYMENT_URL="
    echo "DOCS_DEPLOYMENT_URL=https://rescript-lang.org"
  } >> "$GITHUB_ENV"
else
  SANITIZED_BRANCH=$(echo "$RAW_BRANCH" | tr '[:upper:]' '[:lower:]' | sed -E 's/[^a-z0-9-]+/-/g; s/^-+//; s/-+$//; s/-+/-/g')
  BRANCH_PREFIX="${SANITIZED_BRANCH:0:19}"
  BRANCH_PREFIX="${BRANCH_PREFIX:-preview}"
  BRANCH_DIGEST=$(node --input-type=module -e '
    import {createHash} from "node:crypto";
    process.stdout.write(createHash("sha256").update(process.env.RAW_BRANCH).digest("hex").slice(0, 8));
  ')
  SAFE_BRANCH="${BRANCH_PREFIX}-${BRANCH_DIGEST}"
  {
    echo "SAFE_BRANCH=$SAFE_BRANCH"
    echo "VITE_DEPLOYMENT_URL=https://${SAFE_BRANCH}.rescript-lang.pages.dev"
    echo "DOCS_DEPLOYMENT_URL=https://${SAFE_BRANCH}.rescript-lang.pages.dev"
  } >> "$GITHUB_ENV"
fi
