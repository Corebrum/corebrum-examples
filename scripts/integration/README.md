# Integration hub smoke scripts

- **`smoke_hub_api.sh`** — Quick `curl` checks against `COREBRUM_URL` (default `http://127.0.0.1:6502`): settings and OpenAPI string check for `/api/v1/integration`.

```bash
chmod +x smoke_hub_api.sh
COREBRUM_URL=http://127.0.0.1:6502 ./smoke_hub_api.sh
```

For **MCP** (Claude Desktop / Code), build and configure [`corebrum-mcp`](https://github.com/Corebrum/corebrum/tree/master/contrib/corebrum-mcp) from the main Corebrum repository (`contrib/corebrum-mcp/README.md`).

Per-agent tests (OpenClaw, Claude, Gemini): see [`../agents/README.md`](../agents/README.md).
