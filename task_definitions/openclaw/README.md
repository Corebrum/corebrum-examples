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
   open-claw bridge-start --identity-id <your-identity-id>
   ```

## Setup

### 1. Register OpenClaw Worker

**In CMOS:**
```bash
open-claw register --gateway-url ws://127.0.0.1:18789 --workspace-path ~/.openclaw/workspace --user-id topher
```

**Via CLI:**
```bash
corebrum open-claw register --gateway-url ws://127.0.0.1:18789 --workspace-path ~/.openclaw/workspace
```

**Via API:**
```bash
curl -X POST http://localhost:6502/api/openclaw/register-worker \
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
open-claw bridge-start --identity-id <identity-id>
```

**Via CLI:**
```bash
corebrum open-claw bridge --identity-id <identity-id>
```

### 3. Sync Memory

**In CMOS:**
```bash
open-claw sync-memory --identity-id <identity-id> --workspace-path ~/.openclaw/workspace
```

**Via CLI:**
```bash
corebrum open-claw sync-memory --identity-id <identity-id> --workspace-path ~/.openclaw/workspace
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
  "openclaw_metadata": {
    "workspace_path": "~/.openclaw/workspace",
    "callback_url": "ws://127.0.0.1:18789/callback"
  }
}
```

### OpenClaw Metadata Fields

- **`workspace_path`** (optional): Path to OpenClaw workspace directory
- **`callback_url`** (optional): WebSocket URL for OpenClaw Gateway callbacks

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
POST /api/openclaw/register-worker
```

### Sync Memory
```bash
POST /api/openclaw/sync-memory
```

### Get Workspace Info
```bash
GET /api/openclaw/workspace/{identity_id}
```

### Join Hive
```bash
POST /api/openclaw/join-hive
```

### Leave Hive
```bash
POST /api/openclaw/leave-hive
```

## CMOS Commands

### Register
```bash
open-claw register [--gateway-url URL] [--workspace-path PATH] [--user-id ID]
```

### Sync Memory
```bash
open-claw sync-memory --identity-id ID --workspace-path PATH
```

### Start Bridge
```bash
open-claw bridge-start --identity-id ID [--gateway-url URL]
```

### Stop Bridge
```bash
open-claw bridge-stop
```

### Status
```bash
open-claw status
```

## CLI Commands

### Register
```bash
corebrum open-claw register [--gateway-url URL] [--workspace-path PATH] [--user-id ID]
```

### Sync Memory
```bash
corebrum open-claw sync-memory --identity-id ID --workspace-path PATH
```

### Bridge
```bash
corebrum open-claw bridge --identity-id ID [--gateway-url URL]
```

### Status
```bash
corebrum open-claw status
```

## Troubleshooting

### Bridge Not Appearing

- Check bridge is running: `ps aux | grep "open-claw bridge"`
- Verify Zenoh router is accessible
- Check bridge logs for errors

### Tasks Not Routing to Bridge

- Verify bridge has `openclaw` capability: `open-claw status`
- Check task requires `python` capability (bridge supports `python`)
- Ensure identity_id matches registered identity

### Memory Sync Issues

- Verify workspace path exists and is accessible
- Check identity has Memory feature enabled
- Verify memory files are valid JSON

## Related Documentation

- **Corebrum OpenClaw Integration**: See `../../docs/openclaw-integration.md`
- **Bridge Testing**: See `../../docs/openclaw-bridge-testing.md`
- **CMOS Commands**: See `../../docs/openclaw-cmos-commands.md`
- **Setup Guide**: See `../../docs/openclaw-setup-testing.md`

## Next Steps

1. **Complete WebSocket Implementation**: The bridge currently has a placeholder for WebSocket connection to OpenClaw Gateway
2. **Implement RPC Protocol**: Add support for OpenClaw Gateway RPC calls
3. **Add Callback Handling**: Implement callback URL support for task results
4. **Test End-to-End**: Verify full workflow from task submission to OpenClaw execution
