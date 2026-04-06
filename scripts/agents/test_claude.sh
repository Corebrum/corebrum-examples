#!/usr/bin/env bash
# Test the HTTP surface that Claude uses via corebrum-mcp (same paths as MCP tools).
# This does NOT open Claude Desktop — it proves Corebrum accepts agent-style submits.
#
# Full Claude test: configure Claude Code/Desktop with contrib/corebrum-mcp (see Corebrum repo README).
#
# Environment:
#   COREBRUM_URL, COREBRUM_API_TOKEN (optional)
#   POLL_SECS (default 45) max wait for task terminal state
#
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=_common.sh
source "${SCRIPT_DIR}/_common.sh"
POLL_SECS="${POLL_SECS:-45}"

echo "== Claude path smoke (HTTP = what corebrum-mcp calls) BASE=$BASE =="

echo "-> GET /api/jobs"
curl_json_get "$BASE/api/jobs" | head -c 400
echo
echo

TASK_BODY=$(python3 << 'PY'
import json
td = {
    "name": "claude-agent-smoke",
    "version": "1.0.0",
    "description": "HTTP smoke for Claude/MCP path",
    "compute_logic": {
        "type": "script",
        "language": "python",
        "code": "print('claude_mcp_path_ok')",
        "timeout_seconds": 120,
    },
}
body = {
    "task_definition": td,
    "capability": "python",
    "integration_metadata": {
        "provider": "claude",
        "workspace_path": None,
        "callback_url": None,
    },
}
# omit nulls for cleaner JSON
def strip(d):
    if isinstance(d, dict):
        return {k: strip(v) for k, v in d.items() if v is not None}
    return d
print(json.dumps(strip(body)))
PY
)

echo "-> POST /api/submit (integration_metadata.provider=claude)"
SUBMIT_RESP=$(curl_json_post "$BASE/api/submit" "$TASK_BODY")
echo "$SUBMIT_RESP" | head -c 500
echo
TASK_ID=$(echo "$SUBMIT_RESP" | json_get task_id)
if [[ -z "$TASK_ID" ]]; then
  echo "ERROR: no task_id from submit (daemon/workers running? Zenoh?)." >&2
  exit 1
fi
echo "   task_id=$TASK_ID"

echo
echo "-> Poll GET /api/status/$TASK_ID (max ${POLL_SECS}s)"
deadline=$((SECONDS + POLL_SECS))
state=""
while (( SECONDS < deadline )); do
  ST=$(curl_json_get "$BASE/api/status/${TASK_ID}" || true)
  state=$(echo "$ST" | python3 -c "import json,sys; d=json.load(sys.stdin); print((d.get('data') or {}).get('state') or d.get('status') or '')" 2>/dev/null || true)
  echo "   state=$state"
  if [[ "$state" == COMPLETED || "$state" == FAILED || "$state" == CANCELLED ]]; then
    break
  fi
  sleep 2
done

echo "-> GET /api/results/$TASK_ID (truncated)"
curl_json_get "$BASE/api/results/${TASK_ID}" | head -c 600 || true
echo
echo

echo "OK: Claude/MCP HTTP path smoke finished."
echo "Optional: run  test_claude_mcp.mjs  to stdio-handshake corebrum-mcp (needs Node + built MCP)."
