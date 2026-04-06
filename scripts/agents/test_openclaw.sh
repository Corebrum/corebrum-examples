#!/usr/bin/env bash
# Test OpenClaw integration against Corebrum (HTTP hub + Zenoh-backed flows).
#
# Prerequisites:
#   - Zenoh router reachable (Corebrum default)
#   - corebrum web:  corebrum web   (or your deployment on COREBRUM_URL)
#   - Workspace path exists or will be created by you before sync
#
# Environment:
#   COREBRUM_URL     (default http://127.0.0.1:6502)
#   COREBRUM_API_TOKEN  optional Bearer token
#   OPENCLAW_WORKSPACE  (default ~/.openclaw/workspace)
#   OPENCLAW_GATEWAY    (default ws://127.0.0.1:18789)
#   SKIP_REGISTER=1   skip register-worker (use existing IDENTITY_ID)
#   IDENTITY_ID       when SKIP_REGISTER=1, required for sync + workspace checks
#
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=_common.sh
source "${SCRIPT_DIR}/_common.sh"

export OPENCLAW_WORKSPACE="${OPENCLAW_WORKSPACE:-$HOME/.openclaw/workspace}"
export OPENCLAW_GATEWAY="${OPENCLAW_GATEWAY:-ws://127.0.0.1:18789}"
WORKSPACE="$OPENCLAW_WORKSPACE"
GATEWAY="$OPENCLAW_GATEWAY"

echo "== OpenClaw integration test (BASE=$BASE) =="
echo "   workspace: $WORKSPACE"
echo "   gateway:   $GATEWAY"
echo

echo "-> GET /api/settings/integration"
curl_json_get "$BASE/api/settings/integration" | head -c 500 || true
echo
echo

IDENTITY_ID="${IDENTITY_ID:-}"

if [[ "${SKIP_REGISTER:-}" != "1" ]]; then
  echo "-> POST /api/v1/integration/register-worker"
  BODY=$(python3 << PY
import json
import os
w = os.path.expanduser(os.environ["OPENCLAW_WORKSPACE"])
payload = {
  "provider": "openclaw",
  "gateway_url": os.environ.get("OPENCLAW_GATEWAY", "ws://127.0.0.1:18789"),
  "workspace_path": w,
  "auto_create_user_hive": os.environ.get("AUTO_USER_HIVE", "").lower() in ("1", "true", "yes"),
  "enable_hive_feature_by_default": os.environ.get("ENABLE_HIVE_DEFAULT", "").lower() in ("1", "true", "yes"),
}
uid = os.environ.get("OPENCLAW_USER_ID")
if uid:
  payload["user_identifier"] = uid
print(json.dumps(payload))
PY
)
  RESP=$(curl_json_post "$BASE/api/v1/integration/register-worker" "$BODY" || true)
  echo "$RESP" | head -c 800
  echo
  IDENTITY_ID=$(echo "$RESP" | json_get identity_id)
  if [[ -z "$IDENTITY_ID" ]]; then
    echo "ERROR: register-worker did not return identity_id (Zenoh up? Corebrum web up?)." >&2
    exit 1
  fi
  echo "   identity_id=$IDENTITY_ID"
else
  if [[ -z "$IDENTITY_ID" ]]; then
    echo "ERROR: SKIP_REGISTER=1 requires IDENTITY_ID" >&2
    exit 1
  fi
  echo "   (skipped register; using IDENTITY_ID=$IDENTITY_ID)"
fi

export IDENTITY_ID

echo
echo "-> POST /api/v1/integration/sync-memory"
SYNC_BODY=$(python3 << PY
import json, os
w = os.path.expanduser(os.environ["OPENCLAW_WORKSPACE"])
print(json.dumps({
  "provider": "openclaw",
  "identity_id": os.environ["IDENTITY_ID"],
  "workspace_path": w,
}))
PY
)
curl_json_post "$BASE/api/v1/integration/sync-memory" "$SYNC_BODY" | head -c 500 || {
  echo "WARN: sync-memory failed (workspace missing or empty memory/ is OK)." >&2
}
echo
echo

echo "-> GET /api/v1/integration/workspace/$IDENTITY_ID"
curl_json_get "$BASE/api/v1/integration/workspace/${IDENTITY_ID}" | head -c 800
echo
echo

echo "OK: OpenClaw hub API checks finished."
echo "Next: start OpenClaw Gateway, then  corebrum integration bridge --identity-id $IDENTITY_ID  (or CMOS integration bridge-start)."
