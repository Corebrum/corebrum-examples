# Memory Examples

Examples demonstrating Corebrum's in-memory storage capabilities for fast, ephemeral data access.

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
# First call - computes and caches in memory
corebrum submit-and-wait --file task_definitions/memory/memory_cache_example.yaml \
  --input '{"n": 100}'

# Second call - retrieves from memory cache (very fast)
corebrum submit-and-wait --file task_definitions/memory/memory_cache_example.yaml \
  --input '{"n": 100}'
```

**Key Features:**
- Ephemeral in-memory storage (lost on router restart)
- Very fast access times
- Uses `corebrum/memory/cache/` namespace

### `state_sharing.yaml`

Real-time state sharing between tasks.

```bash
# Task 1: Publish state
corebrum submit --file task_definitions/memory/state_sharing.yaml \
  --input '{"worker_id": "worker-1", "active_tasks": 3}'

# Task 2: Can retrieve state (in another task/worker)
corebrum submit --file task_definitions/memory/state_sharing.yaml \
  --input '{"worker_id": "worker-1", "active_tasks": 5}'
```

**Key Features:**
- Share state across tasks and workers
- Real-time coordination without persistence overhead
- Uses `corebrum/memory/state/` namespace

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

session = zenoh.open()

# Store in memory (ephemeral)
session.put("corebrum/memory/cache/key1", json.dumps(data).encode())

# Retrieve from memory
reply = session.get("corebrum/memory/cache/key1")
if reply:
    data = json.loads(reply.payload.decode())
```

For complete documentation, see the [Memory Backends Guide](https://github.com/corebrum/corebrum/blob/main/docs/memory-backends.md) in the Corebrum repository.

