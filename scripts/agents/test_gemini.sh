#!/usr/bin/env bash
# Test Corebrum submit with integration_metadata.provider=gemini (data-plane tagging).
# Does not call Google Gemini API — your Gemini tool-calling app would use the same REST shape.
#
# Environment: COREBRUM_URL, COREBRUM_API_TOKEN, POLL_SECS (same as test_claude.sh)
#
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=_common.sh
source "${SCRIPT_DIR}/_common.sh"
POLL_SECS="${POLL_SECS:-45}"

echo "== Gemini path smoke (HTTP payload Corebrum accepts) BASE=$BASE =="

TASK_BODY=$(python3 << 'PY'
import json
td = {
    "name": "gemini-agent-smoke",
    "version": "1.0.0",
    "description": "HTTP smoke for Gemini tool-calling path",
    "compute_logic": {
        "type": "script",
        "language": "python",
        "code": "print('gemini_tool_path_ok')",
        "timeout_seconds": 120,
    },
}
body = {
    "task_definition": td,
    "capability": "python",
    "integration_metadata": {"provider": "gemini"},
}
print(json.dumps(body))
PY
)

echo "-> POST /api/submit (integration_metadata.provider=gemini)"
SUBMIT_RESP=$(curl_json_post "$BASE/api/submit" "$TASK_BODY")
echo "$SUBMIT_RESP" | head -c 500
echo
TASK_ID=$(echo "$SUBMIT_RESP" | json_get task_id)
if [[ -z "$TASK_ID" ]]; then
  echo "ERROR: no task_id from submit." >&2
  exit 1
fi
echo "   task_id=$TASK_ID"

echo
echo "-> Poll GET /api/status/$TASK_ID (max ${POLL_SECS}s)"
deadline=$((SECONDS + POLL_SECS))
while (( SECONDS < deadline )); do
  ST=$(curl_json_get "$BASE/api/status/${TASK_ID}" || true)
  state=$(echo "$ST" | python3 -c "import json,sys; d=json.load(sys.stdin); print((d.get('data') or {}).get('state') or '')" 2>/dev/null || true)
  echo "   state=$state"
  [[ "$state" == COMPLETED || "$state" == FAILED || "$state" == CANCELLED ]] && break
  sleep 2
done

echo "-> GET /api/results/$TASK_ID (truncated)"
curl_json_get "$BASE/api/results/${TASK_ID}" | head -c 600 || true
echo
echo

echo "OK: Gemini-tagged submit smoke finished."
echo "Wire this payload shape into Gemini function-calling tools pointing at COREBRUM_URL."
