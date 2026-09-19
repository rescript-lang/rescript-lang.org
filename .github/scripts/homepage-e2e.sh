#!/usr/bin/env bash
set -euo pipefail

# The static server otherwise silently selects a different occupied port.
node --input-type=module -e '
  import {createServer} from "node:net";
  const server = createServer();
  server.once("error", () => {
    console.error("Port 4173 must be free before running homepage tests");
    process.exitCode = 1;
  });
  server.listen(4173, "127.0.0.1", () => server.close());
'

SERVER=$(node --input-type=module -e 'import {fileURLToPath} from "node:url"; console.log(fileURLToPath(import.meta.resolve("@node-cli/static-server")))')
node "$SERVER" --host 127.0.0.1 --port 4173 build/client &
SERVER_PID=$!
trap 'kill "$SERVER_PID" 2>/dev/null || true; wait "$SERVER_PID" 2>/dev/null || true' EXIT

for _ in {1..30}; do
  if curl --fail --silent --max-time 2 http://127.0.0.1:4173/ > /dev/null; then
    yarn ci:test:e2e "$@"
    exit 0
  fi
  kill -0 "$SERVER_PID"
  sleep 1
done

echo "Homepage test server did not become ready" >&2
exit 1
