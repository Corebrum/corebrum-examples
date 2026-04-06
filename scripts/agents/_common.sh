#!/usr/bin/env bash
# Shared helpers for agent test scripts (source from same directory).
# shellcheck disable=SC2034

: "${COREBRUM_URL:=http://127.0.0.1:6502}"
BASE="${COREBRUM_URL%/}"

curl_json_get() {
  local url="$1"
  local headers=(-H "Accept: application/json")
  if [[ -n "${COREBRUM_API_TOKEN:-}" ]]; then
    headers+=(-H "Authorization: Bearer ${COREBRUM_API_TOKEN}")
  fi
  curl -sS -f "${headers[@]}" "$url"
}

curl_json_post() {
  local url="$1"
  local body="$2"
  local headers=(
    -H "Accept: application/json"
    -H "Content-Type: application/json"
  )
  if [[ -n "${COREBRUM_API_TOKEN:-}" ]]; then
    headers+=(-H "Authorization: Bearer ${COREBRUM_API_TOKEN}")
  fi
  curl -sS -f "${headers[@]}" -d "$body" "$url"
}

json_get() {
  python3 -c "import json,sys; print(json.load(sys.stdin).get('$1') or '')"
}
