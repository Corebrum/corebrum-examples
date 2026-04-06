# OpenClaw Integration Examples

This directory contains examples of tasks that integrate with OpenClaw, a personal AI assistant platform. These examples demonstrate how to use Corebrum as a network coordination layer for OpenClaw instances, handling compute, identity, and memory management.

## Overview

OpenClaw integration allows you to:

- **Register OpenClaw instances** as Corebrum workers
- **Sync workspace memory** between OpenClaw and Corebrum
- **Submit tasks** with OpenClaw-specific metadata
- **Share identity and memory** across OpenClaw instances via hives
- **Coordinate compute** across multiple OpenClaw instances

## Prerequisites

1. **OpenClaw installed**: Make sure OpenClaw is installed and configured
2. **OpenClaw Gateway running**: Start the OpenClaw Gateway (typically on `ws://127.0.0.1:18789`)
3. **Corebrum bridge running**: Start the OpenClaw bridge in CMOS:
   ```bash
   integration bridge-start --identity-id <your-identity-id>
   ```

## Automated API tests

From the **corebrum-examples** repo root, [`scripts/agents/test_openclaw.sh`](../../scripts/agents/test_openclaw.sh) exercises the integration hub (`register-worker`, `sync-memory`, `workspace/{id}`). Claude- and Gemini-oriented HTTP checks live in the same folder; see [`scripts/agents/README.md`](../../scripts/agents/README.md).

## Setup

### 1. Register OpenClaw Worker

**In CMOS:**
```bash
integration register --gateway-url ws://127.0.0.1:18789 --workspace-path ~/.openclaw/workspace --user-id topher
```

**Via CLI:**
```bash
corebrum integration register --gateway-url ws://127.0.0.1:18789 --workspace-path ~/.openclaw/workspace
```

**Via API:**
```bash
curl -X POST http://localhost:6502/api/v1/integration/register-worker \
  -H "Content-Type: application/json" \
  -d '{
    "gateway_url": "ws://127.0.0.1:18789",
    "workspace_path": "~/.openclaw/workspace",
    "user_identifier": "topher"
  }'
```

### 2. Start Bridge

**In CMOS:**
```bash
integration bridge-start --identity-id <identity-id>
```

**Via CLI:**
```bash
corebrum integration bridge --identity-id <identity-id>
```

### 3. Sync Memory

**In CMOS:**
```bash
integration sync-memory --identity-id <identity-id> --workspace-path ~/.openclaw/workspace
```

**Via CLI:**
```bash
corebrum integration sync-memory --identity-id <identity-id> --workspace-path ~/.openclaw/workspace
```

## Examples

### 1. Basic OpenClaw Test (`openclaw-test.json`)

A simple test task that verifies OpenClaw integration is working.

**Features:**
- Includes OpenClaw metadata (workspace path, callback URL)
- Uses Python script execution
- Demonstrates basic task submission with OpenClaw context

**Usage:**
```bash
# Via CLI
corebrum submit --file task_definitions/openclaw/openclaw-test.json

# Via API
curl -X POST http://localhost:6502/api/submit \
  -H "Content-Type: application/json" \
  -d @task_definitions/openclaw/openclaw-test.json

# In CMOS
submit
# Then paste the JSON content
```

### 2. OpenClaw with Memory Context (`openclaw-memory-task.json`)

A task that uses OpenClaw workspace memory context.

**Features:**
- Accesses OpenClaw workspace memory
- Demonstrates memory-aware task execution
- Shows identity-scoped memory access

**Usage:**
```bash
corebrum submit --file task_definitions/openclaw/openclaw-memory-task.json
```

### 3. OpenClaw Hive Task (`openclaw-hive-task.json`)

A task that leverages shared hive memory across OpenClaw instances.

**Features:**
- Uses hive memory for shared context
- Demonstrates multi-instance coordination
- Shows hive-based memory sharing

**Usage:**
```bash
corebrum submit --file task_definitions/openclaw/openclaw-hive-task.json
```

### 4. Browser Automation (`openclaw-browser-example.json`)

Basic browser automation using Playwright.

**Features:**
- Launches headless Chromium browser
- Navigates to websites
- Extracts page information (title, headings, content)
- Demonstrates browser capability via OpenClaw bridge

**Usage:**
```bash
corebrum submit --file task_definitions/openclaw/openclaw-browser-example.json
```

**Dependencies:** Playwright will be automatically installed by Corebrum workers

### 5. Web Scraping (`openclaw-browser-scraping.json`)

Advanced web scraping example extracting structured data from web pages.

**Features:**
- Extracts headings, links, and paragraphs
- Structured data extraction
- Network idle waiting for dynamic content
- Demonstrates data collection patterns

**Usage:**
```bash
corebrum submit --file task_definitions/openclaw/openclaw-browser-scraping.json
```

### 6. Browser Interaction (`openclaw-browser-interaction.json`)

Browser interaction example - clicking, form filling, navigation.

**Features:**
- Form filling and button clicking
- Page navigation
- Custom viewport and user agent
- Action logging and state tracking

**Usage:**
```bash
corebrum submit --file task_definitions/openclaw/openclaw-browser-interaction.json
```

### 7. Browser with Auto-Install (`openclaw-browser-with-install.json`)

Browser automation that automatically installs Playwright browser binaries if needed.

**Features:**
- Automatic Playwright browser installation
- Handles missing dependencies gracefully
- Useful for workers that don't have browsers pre-installed
- Longer timeout to account for installation time

**Usage:**
```bash
corebrum submit --file task_definitions/openclaw/openclaw-browser-with-install.json
```

**Note**: This example includes installation logic, but OpenClaw bridge workers should already have browsers installed.

## Task Definition Structure

### Basic OpenClaw Task

```json
{
  "task_definition": {
    "name": "openclaw-example",
    "version": "1.0.0",
    "description": "Example OpenClaw task",
    "compute_logic": {
      "type": "script",
      "language": "python",
      "code": "print('Hello from OpenClaw!')",
      "timeout_seconds": 30
    }
  },
  "identity_id": "your-identity-id",
  "integration_metadata": {
    "provider": "openclaw",
    "workspace_path": "~/.openclaw/workspace",
    "callback_url": "ws://127.0.0.1:18789/callback"
  }
}
```

### Integration metadata fields (OpenClaw)

- **`provider`** (required for typed clients): `openclaw` | `claude` | `gemini` | `custom`
- **`workspace_path`** (optional): Path to OpenClaw workspace directory
- **`callback_url`** (optional): WebSocket URL for OpenClaw Gateway callbacks

## Browser Automation

OpenClaw bridge supports browser automation via the `browser` capability. Tasks can use Playwright to:

- **Navigate websites**: Load and interact with web pages
- **Extract data**: Scrape content, headings, links, etc.
- **Fill forms**: Automate form submissions
- **Click elements**: Interact with buttons and links
- **Take screenshots**: Capture page visuals
- **Handle dynamic content**: Wait for JavaScript to load

### Browser Task Requirements

1. **Playwright dependency**: Tasks using browser automation should include Playwright in their code
2. **Browser capability**: Ensure the task is routed to a worker with `browser` capability (OpenClaw bridge has this)
3. **Timeout**: Browser tasks may need longer timeouts (60-120 seconds)

### Example Browser Task Structure

```json
{
  "task_definition": {
    "name": "browser-task",
    "compute_logic": {
      "type": "script",
      "language": "python",
      "code": "import asyncio\nfrom playwright.async_api import async_playwright\n\nasync def main():\n    async with async_playwright() as p:\n        browser = await p.chromium.launch(headless=True)\n        page = await browser.new_page()\n        await page.goto('https://example.com')\n        title = await page.title()\n        await browser.close()\n        return {'title': title}\n\nresult = asyncio.run(main())\nprint(json.dumps(result))",
      "timeout_seconds": 60
    }
  },
  "integration_metadata": {
    "provider": "openclaw",
    "workspace_path": "~/.openclaw/workspace"
  }
}
```

### Browser Automation Best Practices

1. **Use headless mode**: Set `headless=True` for server environments
2. **Wait for content**: Use `wait_until='networkidle'` for dynamic pages
3. **Handle errors**: Wrap browser operations in try/except blocks
4. **Clean up**: Always close browsers to free resources
5. **Set timeouts**: Configure appropriate timeouts for slow-loading pages

### Playwright Installation

**Important**: Playwright requires both the Python package AND browser binaries:

1. **Python Package**: Corebrum will **automatically install** the `playwright` Python package if you include it in the `dependencies` field:
   ```json
   {
     "task_definition": {
       "dependencies": ["playwright"],
       ...
     }
   }
   ```

2. **Browser Binaries**: Browser binaries need to be installed separately. The examples handle this automatically:
   - **Simple examples** (`openclaw-browser-example.json`): Try to use browser, install if missing
   - **With-install example** (`openclaw-browser-with-install.json`): Explicitly checks and installs browsers

**For OpenClaw Bridge Workers**: Browser binaries should already be available since OpenClaw uses browser automation. The bridge has `browser` capability.

**For Regular Workers**: Browser binaries will be auto-installed by the task code if missing (adds ~30-60 seconds to first run).

**Manual Installation** (optional, for faster first run):
```bash
# On worker machines
pip install playwright
playwright install chromium
```

## Key Features

### Identity Management

- Each OpenClaw instance gets a unique Corebrum identity
- Identity stores workspace path and user identifier
- Memory feature enabled by default for OpenClaw identities

### Memory Synchronization

- Syncs OpenClaw workspace memory files to Corebrum
- Memory stored in identity-scoped persistent storage
- Accessible via Corebrum memory API

### Hive Integration

- OpenClaw instances can join user-specific hives
- Shared memory across instances in the same hive
- Automatic hive creation for users

### Worker Registration

- OpenClaw instances register as Corebrum workers
- Bridge connects OpenClaw Gateway to Corebrum network
- Tasks routed to OpenClaw workers via bridge

## API Endpoints

### Register Worker
```bash
POST /api/v1/integration/register-worker
```

### Sync Memory
```bash
POST /api/v1/integration/sync-memory
```

### Get Workspace Info
```bash
GET /api/v1/integration/workspace/{identity_id}
```

### Join Hive
```bash
POST /api/v1/integration/join-hive
```

### Leave Hive
```bash
POST /api/v1/integration/leave-hive
```

## CMOS Commands

### Register
```bash
integration register [--gateway-url URL] [--workspace-path PATH] [--user-id ID]
```

### Sync Memory
```bash
integration sync-memory --identity-id ID --workspace-path PATH
```

### Start Bridge
```bash
integration bridge-start --identity-id ID [--gateway-url URL]
```

### Stop Bridge
```bash
integration bridge-stop
```

### Status
```bash
integration status
```

## CLI Commands

### Register
```bash
corebrum integration register [--gateway-url URL] [--workspace-path PATH] [--user-id ID]
```

### Sync Memory
```bash
corebrum integration sync-memory --identity-id ID --workspace-path PATH
```

### Bridge
```bash
corebrum integration bridge --identity-id ID [--gateway-url URL]
```

### Status
```bash
corebrum integration status
```

## Troubleshooting

### Bridge Not Appearing

- Check bridge is running: `ps aux | grep "corebrum integration bridge"`
- Verify Zenoh router is accessible
- Check bridge logs for errors

### Tasks Not Routing to Bridge

- Verify bridge has `openclaw` capability: `integration status`
- Check task requires `python` capability (bridge supports `python`)
- Ensure identity_id matches registered identity

### Memory Sync Issues

- Verify workspace path exists and is accessible
- Check identity has Memory feature enabled
- Verify memory files are valid JSON

## Related Documentation

- **Agent integration hub**: See Corebrum `docs/agent-integration.md` and `docs/openclaw-integration.md`
- **Bridge Testing**: See `../../docs/openclaw-bridge-testing.md`
- **CMOS Commands**: See `../../docs/openclaw-cmos-commands.md`
- **Setup Guide**: See `../../docs/openclaw-setup-testing.md`

## Next Steps

1. **Complete WebSocket Implementation**: The bridge currently has a placeholder for WebSocket connection to OpenClaw Gateway
2. **Implement RPC Protocol**: Add support for OpenClaw Gateway RPC calls
3. **Add Callback Handling**: Implement callback URL support for task results
4. **Test End-to-End**: Verify full workflow from task submission to OpenClaw execution
