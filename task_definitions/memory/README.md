# Memory Examples

Examples demonstrating Corebrum's memory system capabilities, including persistent identity memory, content-based search, ephemeral vs durable memory, and hive memory collaboration.

## Prerequisites

1. **Start Zenoh Router** (no storage backend needed for memory):
   ```bash
   zenohd
   ```

2. **Start Corebrum Daemon**:
   ```bash
   corebrum daemon --zenoh-router tcp://localhost:7447
   ```

## Examples

### `memory_cache_example.yaml`

Fast in-memory caching for repeated computations.

```bash
# First call - computes and caches in memory (uses default n=100 if no input provided)
corebrum submit-and-wait --file task_definitions/memory/memory_cache_example.yaml \
  --input '{"n": 100}'

# Second call - retrieves from memory cache (very fast)
corebrum submit-and-wait --file task_definitions/memory/memory_cache_example.yaml \
  --input '{"n": 100}'

# Without input - uses default value of n=100
corebrum submit-and-wait --file task_definitions/memory/memory_cache_example.yaml
```

**Key Features:**
- Ephemeral in-memory storage (lost on router restart)
- Very fast access times
- Uses `corebrum/memory/cache/` namespace
- Default value of `n=100` if no input provided

### `state_sharing.yaml`

Real-time state sharing between tasks.

```bash
# Task 1: Publish state
corebrum submit --file task_definitions/memory/state_sharing.yaml \
  --input '{"worker_id": "worker-1", "active_tasks": 3}'

# Task 2: Update state (in another task/worker)
corebrum submit --file task_definitions/memory/state_sharing.yaml \
  --input '{"worker_id": "worker-1", "active_tasks": 5}'

# Without input - uses defaults (worker-unknown, active_tasks=0)
corebrum submit --file task_definitions/memory/state_sharing.yaml
```

**Key Features:**
- Share state across tasks and workers via pub/sub
- Real-time coordination without persistence overhead
- Uses `corebrum/memory/state/` namespace
- Default values: `worker_id="worker-unknown"`, `active_tasks=0` if not provided
- **Note**: `session.get()` verification may not work for ephemeral memory without a storage backend, but the publish succeeds and data is available to subscribers

## Memory vs Storage

| Feature | Memory | Storage |
|---------|--------|---------|
| Persistence | No (ephemeral) | Yes (persistent) |
| Performance | Very Fast | Fast |
| Use Case | Cache, temporary data | Long-term storage |
| Key Namespace | `corebrum/memory/*` | `corebrum/storage/*` |

## Using Memory in Tasks

All examples use Zenoh's native API for memory (same as storage, different namespace):

```python
import zenoh
import json
import sys

# Create Zenoh config and session
config = zenoh.Config()
session = zenoh.open(config)

# Get input values from inputs dict (always available in wrapper)
# Inputs are passed via --input flag and available as 'inputs' dict
n = inputs.get('n', 100)  # Use default if not provided

# Store in memory (ephemeral)
session.put("corebrum/memory/cache/key1", json.dumps(data).encode())

# Retrieve from memory
# session.get() returns an iterator of replies
data = None
replies = session.get("corebrum/memory/cache/key1")
for reply in replies:
    try:
        sample = reply.ok()
        data = json.loads(sample.payload.decode())
        break  # Use first successful reply
    except Exception as e:
        print(f"DEBUG: Error processing reply: {e}", file=sys.stderr)
        continue

if data:
    print(f"Retrieved: {data}")
```

**Important Notes:**
- Always create a `zenoh.Config()` and pass it to `zenoh.open(config)` - required by Zenoh Python API
- Inputs are accessed via `inputs.get('key', default_value)` - the `inputs` dict is always available
- `session.get()` returns an iterator - iterate over replies and use `reply.ok()` to get the sample
- For ephemeral memory without a storage backend, `session.get()` may not work immediately after `session.put()` - the data is published and available to subscribers, but querying requires a storage backend or queryable

## New Features (Memory Architecture v2)

### Content-Based Search

Search memories by content using BM25 text search:

```bash
corebrum submit-and-wait --file task_definitions/memory/memory_search_example.yaml \
  --input '{"key_id": "your-key-id", "query": "door closed"}'
```

### Ephemeral vs Durable Memory

Store memories with explicit types:

```bash
# Store durable memory (long-term)
corebrum submit-and-wait --file task_definitions/memory/memory_with_type_example.yaml \
  --input '{"key_id": "your-key-id", "memory_key": "preference", "value": "Python", "memory_type": "durable"}'

# Store ephemeral memory (temporary, auto-expires)
corebrum submit-and-wait --file task_definitions/memory/memory_with_type_example.yaml \
  --input '{"key_id": "your-key-id", "memory_key": "observation", "value": "Door closed", "memory_type": "ephemeral"}'
```

### Memory Limits and Statistics

Configure limits and check statistics:

```bash
# Check memory statistics
corebrum submit-and-wait --file task_definitions/memory/memory_limits_example.yaml \
  --input '{"key_id": "your-key-id", "action": "stats"}'

# Set memory limits
corebrum submit-and-wait --file task_definitions/memory/memory_limits_example.yaml \
  --input '{"key_id": "your-key-id", "action": "set_limits"}'

# Trigger compaction
corebrum submit-and-wait --file task_definitions/memory/memory_limits_example.yaml \
  --input '{"key_id": "your-key-id", "action": "compact"}'
```

## Documentation

- [Memory Architecture Guide](https://github.com/corebrum/corebrum/blob/main/docs/memory-architecture.md) - Complete guide to memory features
- [Memory Backends Guide](https://github.com/corebrum/corebrum/blob/main/docs/memory-backends.md) - Zenoh memory backend configuration

