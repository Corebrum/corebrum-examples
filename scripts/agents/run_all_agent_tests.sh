#!/usr/bin/env bash
# Run OpenClaw, Claude (HTTP), and Gemini (HTTP) test scripts in sequence.
# Fails fast on first non-zero exit (set +e to continue all).
#
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "######## OpenClaw ########"
bash "${SCRIPT_DIR}/test_openclaw.sh"
echo

echo "######## Claude (HTTP) ########"
bash "${SCRIPT_DIR}/test_claude.sh"
echo

echo "######## Gemini (HTTP) ########"
bash "${SCRIPT_DIR}/test_gemini.sh"
echo

echo "All agent test scripts completed OK."
