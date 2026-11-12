#!/usr/bin/env bash
# Fan out GPU probe jobs across the Cortex mesh and print where each ran.
#
# Prerequisites:
#   - Zenoh router reachable from this host
#   - At least one daemon started with auto-hardware (no --worker-count) on a GPU machine
#   - New cortex binary (GPU fleet support)
#
# Usage:
#   ./scripts/test_gpu_mesh.sh
#   JOBS=8 ZENOH_ROUTER=tcp://192.168.8.196:7447 ./scripts/test_gpu_mesh.sh
#   CORTEX_BIN=/path/to/cortex JOBS=4 ./scripts/test_gpu_mesh.sh

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
if [[ -z "${CORTEX_BIN:-}" ]]; then
  for candidate in \
    "${HOME}/corebrum-cortex/target/release/cortex" \
    "/home/nvidia/corebrum-cortex/target/release/cortex" \
    cortex; do
    if command -v "$candidate" >/dev/null 2>&1 || [[ -x "$candidate" ]]; then
      CORTEX_BIN="$candidate"
      break
    fi
  done
  CORTEX_BIN="${CORTEX_BIN:-cortex}"
fi
# Must match the router your CMOS daemon uses (not always 127.0.0.1 on fleet meshes).
ROUTER="${ZENOH_ROUTER:-tcp://192.168.8.196:7447}"
JOBS="${JOBS:-4}"
PARALLEL="${PARALLEL:-1}"
TASK="${TASK:-$ROOT/cortex/task_definitions/fleet/gpu_worker_probe.yaml}"
HEAVY="${HEAVY:-0}"

if [[ ! -f "$TASK" ]]; then
  echo "Task file not found: $TASK" >&2
  exit 1
fi

if [[ "$HEAVY" == "1" ]]; then
  TASK="$ROOT/cortex/task_definitions/fleet/gpu_mesh_load_balance.yaml"
fi

echo "Cortex: $CORTEX_BIN"
echo "Router: $ROUTER"
echo "Task:   $TASK"
echo "Jobs:   $JOBS"

daemon_count="$(pgrep -fc '[c]ortex daemon' 2>/dev/null || echo 0)"
if [[ "$daemon_count" -eq 0 ]]; then
  echo "ERROR: No 'cortex daemon' on this host. In CMOS: start-workers (Enter = auto GPU layout)." >&2
  exit 1
elif [[ "$daemon_count" -gt 1 ]]; then
  echo "WARN: $daemon_count cortex daemon processes — stop extras (CMOS stop-workers, then one start-workers)." >&2
fi
echo

TMPDIR="$(mktemp -d)"
trap 'rm -rf "$TMPDIR"' EXIT

run_one() {
  local id="$1"
  local out="$TMPDIR/job_${id}.json"
  export CORTEX_PROBE_JOB_ID="probe-${id}"
  # Tee output so submit-and-wait progress is visible (redirect-only looks hung for minutes).
  if "$CORTEX_BIN" --zenoh-router "$ROUTER" submit-and-wait --file "$TASK" 2>&1 | tee "$out"; then
    echo "ok $id"
  else
    echo "fail $id" >&2
    tail -20 "$out" >&2
  fi
}

export CORTEX_BIN ROUTER TASK TMPDIR
if [[ "$PARALLEL" == "1" ]]; then
  for i in $(seq 1 "$JOBS"); do
    run_one "$i" &
  done
  wait
else
  for i in $(seq 1 "$JOBS"); do
    echo "→ job $i/$JOBS..."
    run_one "$i"
  done
fi

echo
echo "=== Results ==="
python3 - <<'PY'
import json
import glob
import os

tmpdir = os.environ["TMPDIR"]
paths = sorted(glob.glob(os.path.join(tmpdir, "job_*.json")))
hosts = {}
cuda_hosts = set()
def extract_task_payload(raw: str):
    marker = "Task Results:"
    idx = raw.find(marker)
    if idx >= 0:
        blob = raw[idx + len(marker) :].strip()
        try:
            return json.loads(blob)
        except json.JSONDecodeError:
            pass
    start = raw.find("{")
    if start >= 0:
        depth = 0
        for end in range(start, len(raw)):
            if raw[end] == "{":
                depth += 1
            elif raw[end] == "}":
                depth -= 1
                if depth == 0:
                    try:
                        return json.loads(raw[start : end + 1])
                    except json.JSONDecodeError:
                        break
    return None


for path in paths:
    raw = open(path, encoding="utf-8", errors="replace").read()
    payload = extract_task_payload(raw)
    if not payload:
        print(path, ":", raw[:200].replace("\n", " "))
        continue
    if payload.get("status") not in ("COMPLETED", "FAILED", "SUCCESS") and "task_definition" in payload:
        # Picked up DEBUG submit JSON — treat as failed parse
        err_path = path.replace(".json", ".err")
        tail = ""
        if os.path.isfile(err_path):
            tail = open(err_path, encoding="utf-8", errors="replace").read()[-300:]
        print(path, ": no Task Results in stdout", tail.replace("\n", " "))
        continue
    body = payload.get("result") or payload
    if isinstance(body, str):
        try:
            body = json.loads(body)
        except json.JSONDecodeError:
            body = {"raw": body}
    artifacts = payload.get("artifacts") or body.get("artifacts")
    if isinstance(artifacts, dict) and "result.json" in artifacts:
        try:
            inner = json.loads(artifacts["result.json"])
            if isinstance(inner, dict):
                body = {**body, **inner} if isinstance(body, dict) else inner
        except json.JSONDecodeError:
            pass
    host = body.get("hostname", "?")
    hosts[host] = hosts.get(host, 0) + 1
    if body.get("torch_cuda_available") or body.get("device_name") or body.get("gpu_line"):
        cuda_hosts.add(host)
    print(json.dumps(body, indent=2))
    print("---")

print()
print("Jobs per hostname:", dict(sorted(hosts.items())))
print("Hosts that reported CUDA:", sorted(cuda_hosts) if cuda_hosts else "(none — check GPU workers / auto-hardware daemon)")
PY
