# Per–AI-agent test scripts

Scripts live next to the [integration hub smoke](../integration/smoke_hub_api.sh). They assume **`corebrum web`** (or your deployment) is listening on **`COREBRUM_URL`** (default `http://127.0.0.1:6502`) and that **Zenoh** is available for submit/register flows.

| Script | What it validates |
|--------|-------------------|
| [`test_openclaw.sh`](./test_openclaw.sh) | `GET /api/settings/integration`, `POST /api/v1/integration/register-worker`, `sync-memory`, `GET workspace/{id}` |
| [`test_claude.sh`](./test_claude.sh) | Same HTTP paths **corebrum-mcp** uses: `GET /api/jobs`, `POST /api/submit` with `integration_metadata.provider=claude`, status/results poll |
| [`test_gemini.sh`](./test_gemini.sh) | `POST /api/submit` with `integration_metadata.provider=gemini` (no Google API call) |
| [`test_claude_mcp.mjs`](./test_claude_mcp.mjs) | Optional **stdio MCP** handshake (`initialize` + `tools/list`) against built **`corebrum-mcp`** |
| [`run_all_agent_tests.sh`](./run_all_agent_tests.sh) | Runs the three shell tests in order |

## Quick start

```bash
cd scripts/agents
chmod +x *.sh

export COREBRUM_URL=http://127.0.0.1:6502
# optional: export COREBRUM_API_TOKEN=...

./test_openclaw.sh
./test_claude.sh
./test_gemini.sh
```

Or everything:

```bash
./run_all_agent_tests.sh
```

## OpenClaw options

- `OPENCLAW_WORKSPACE` — default `~/.openclaw/workspace`
- `OPENCLAW_GATEWAY` — default `ws://127.0.0.1:18789`
- `OPENCLAW_USER_ID` — passed as `user_identifier` when set
- `SKIP_REGISTER=1` and `IDENTITY_ID=...` — skip register, only sync + workspace GET

## Claude MCP (optional)

Build the server from the main Corebrum tree:

```bash
cd ../../corebrum/contrib/corebrum-mcp   # adjust if your clone layout differs
npm install && npm run build
```

Then from `scripts/agents`:

```bash
export COREBRUM_MCP_JS=/absolute/path/to/corebrum/contrib/corebrum-mcp/dist/index.js
node test_claude_mcp.mjs
```

If `corebrum` and `corebrum-examples` are **siblings**, the default path inside `test_claude_mcp.mjs` should resolve without `COREBRUM_MCP_JS`.

## Dependencies

- `bash`, `curl`, `python3` (for JSON bodies and small parsing)
- **Workers + daemon** for submit tests: `test_claude.sh` / `test_gemini.sh` need the mesh to run the Python task; register/sync tests need Zenoh storage for identities.
