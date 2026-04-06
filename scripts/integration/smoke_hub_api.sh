#!/usr/bin/env bash
# Smoke-test Corebrum agent integration hub (requires `corebrum web` or packaged server).
# Usage: COREBRUM_URL=http://127.0.0.1:6502 ./smoke_hub_api.sh

set -euo pipefail
BASE="${COREBRUM_URL:-http://127.0.0.1:6502}"
BASE="${BASE%/}"

echo "== Corebrum integration hub smoke (BASE=$BASE) =="

echo "-> GET /api/settings/integration"
curl -sS -f "$BASE/api/settings/integration" | head -c 400 || true
echo ""
echo ""

echo "-> GET OpenAPI tag check (integration paths present)"
curl -sS -f "$BASE/api/openapi.json" | grep -q "v1/integration" && echo "OK: openapi mentions v1/integration" || {
  echo "WARN: could not confirm v1/integration in openapi (is server up?)"
}

echo ""
echo "Done. For full register/sync tests, run Corebrum and Zenoh, then:"
echo "  curl -X POST $BASE/api/v1/integration/register-worker -H 'Content-Type: application/json' \\"
echo "    -d '{\"gateway_url\":\"ws://127.0.0.1:18789\",\"workspace_path\":\"'$HOME'/.openclaw/workspace\"}'"
